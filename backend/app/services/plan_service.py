from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import uuid
import requests

from app.models.plan import Plan, PlanActivity
from app.schemas.plan import PlanCreateRequest, PlanUpdateRequest
from app.schemas.user import VisitedPlace
from app.services.recommendation_service import RecommendationService
from app.core.config import settings


class PlanService:
    def __init__(self, db: Session):
        self.db = db
        self.rec_service = RecommendationService(db)
        self.google_maps_api_key = settings.GOOGLE_MAPS_API_KEY
    
    def get_place_details_from_google(self, place_id: str) -> Optional[Dict[str, Any]]:
        """
        Obtener detalles de un lugar desde Google Places API usando place_id
        """
        if not self.google_maps_api_key:
            print("⚠ Google Maps API Key no configurada")
            return None
        
        url = "https://maps.googleapis.com/maps/api/place/details/json"
        
        params = {
            "place_id": place_id,
            "fields": "name,geometry,formatted_address,types,rating,user_ratings_total",
            "language": "es",
            "key": self.google_maps_api_key
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data.get("status") != "OK":
                print(f"⚠ Google Place Details API error: {data.get('status')}")
                return None
            
            result = data["result"]
            
            return {
                "place_id": place_id,
                "name": result.get("name"),
                "latitude": result["geometry"]["location"]["lat"],
                "longitude": result["geometry"]["location"]["lng"],
                "address": result.get("formatted_address"),
                "types": result.get("types", []),
                "rating": result.get("rating"),
                "user_ratings_total": result.get("user_ratings_total", 0)
            }
            
        except Exception as e:
            print(f"⚠ Error obteniendo detalles de Google Places: {e}")
            return None
    
    def get_route_details(
        self,
        origin_lat: float,
        origin_lon: float,
        dest_lat: float,
        dest_lon: float,
        mode: str = "transit"
    ) -> Dict[str, Any]:
        """
        Obtener detalles de ruta real usando Google Directions API
        
        Args:
            origin_lat: Latitud origen
            origin_lon: Longitud origen
            dest_lat: Latitud destino
            dest_lon: Longitud destino
            mode: Modo de transporte (driving, walking, bicycling, transit)
        
        Returns:
            Detalles de la ruta incluyendo tiempo, distancia y pasos
        """
        if not self.google_maps_api_key:
            # Fallback a cálculo básico si no hay API key
            return self._get_basic_route(origin_lat, origin_lon, dest_lat, dest_lon, mode)
        
        url = "https://maps.googleapis.com/maps/api/directions/json"
        
        params = {
            "origin": f"{origin_lat},{origin_lon}",
            "destination": f"{dest_lat},{dest_lon}",
            "mode": mode,
            "language": "es",
            "key": self.google_maps_api_key
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data.get("status") != "OK":
                print(f"⚠ Google Directions API error: {data.get('status')}")
                return self._get_basic_route(origin_lat, origin_lon, dest_lat, dest_lon, mode)
            
            route = data["routes"][0]
            leg = route["legs"][0]
            
            return {
                "mode": mode,
                "distance_km": round(leg["distance"]["value"] / 1000, 2),
                "duration_minutes": round(leg["duration"]["value"] / 60),
                "duration_text": leg["duration"]["text"],
                "distance_text": leg["distance"]["text"],
                "start_address": leg["start_address"],
                "end_address": leg["end_address"],
                "steps": [
                    {
                        "instruction": step["html_instructions"],
                        "distance": step["distance"]["text"],
                        "duration": step["duration"]["text"]
                    }
                    for step in leg["steps"][:5]  # Primeros 5 pasos
                ],
                "polyline": route["overview_polyline"]["points"]
            }
            
        except Exception as e:
            print(f"⚠ Error llamando a Google Directions API: {e}")
            return self._get_basic_route(origin_lat, origin_lon, dest_lat, dest_lon, mode)
    
    def _get_basic_route(
        self,
        origin_lat: float,
        origin_lon: float,
        dest_lat: float,
        dest_lon: float,
        mode: str
    ) -> Dict[str, Any]:
        """Cálculo básico de ruta sin Google API"""
        distance_km = self.rec_service.calculate_distance(
            origin_lat, origin_lon, dest_lat, dest_lon
        )
        
        # Velocidades promedio por modo (km/h)
        speeds = {
            "walking": 5,
            "bicycling": 15,
            "driving": 30,
            "transit": 20
        }
        
        speed = speeds.get(mode, 20)
        duration_minutes = int((distance_km / speed) * 60) + 5  # +5 min buffer
        
        return {
            "mode": mode,
            "distance_km": distance_km,
            "duration_minutes": duration_minutes,
            "duration_text": f"{duration_minutes} min",
            "distance_text": f"{distance_km} km",
            "start_address": f"{origin_lat}, {origin_lon}",
            "end_address": f"{dest_lat}, {dest_lon}",
            "steps": [],
            "polyline": None
        }
    
    def get_all_transport_options(
        self,
        origin_lat: float,
        origin_lon: float,
        dest_lat: float,
        dest_lon: float
    ) -> Dict[str, Dict[str, Any]]:
        """
        Obtener opciones de transporte para una ruta
        Retorna tiempos y distancias para todos los modos
        """
        modes = ["walking", "bicycling", "transit", "driving"]
        options = {}
        
        for mode in modes:
            route = self.get_route_details(
                origin_lat, origin_lon,
                dest_lat, dest_lon,
                mode
            )
            options[mode] = {
                "duration_minutes": route["duration_minutes"],
                "duration_text": route["duration_text"],
                "distance_km": route["distance_km"],
                "distance_text": route["distance_text"]
            }
        
        return options
    
    def create_optimized_plan(self, plan_request: PlanCreateRequest) -> Dict[str, Any]:
        """
        Crear un plan optimizado de actividades
        """
        # Generate unique plan_id
        plan_id = f"plan_{uuid.uuid4().hex[:12]}"
        
        # Fetch activity details from Google Places API
        activities_details = []
        
        # Mapa de duraciones estimadas por tipo de lugar
        duration_map = {
            "museums": 90,
            "parks": 60,
            "restaurants": 90,
            "cafes": 45,
            "bars": 120,
            "nightlife": 180,
            "shopping": 120,
            "cultural": 90,
            "attraction": 90,
            "entertainment": 120
        }
        
        for activity_input in plan_request.activities:
            # Obtener detalles del lugar desde Google Places API
            print(f"🔍 Obteniendo detalles de Google Places: {activity_input.id}")
            google_place = self.get_place_details_from_google(activity_input.id)
            
            if not google_place:
                raise ValueError(f"No se pudo obtener información del lugar: {activity_input.id}")
            
            # Estimar duración según el tipo
            estimated_duration = duration_map.get(activity_input.type, 90)
            
            place_data = {
                "type": "place",
                "id": google_place["place_id"],
                "name": google_place["name"],
                "category": activity_input.type,  # Guardar categoría original
                "latitude": google_place["latitude"],
                "longitude": google_place["longitude"],
                "estimated_duration": estimated_duration,
                "source": "google_places",
                "rating": google_place.get("rating"),
                "types": google_place.get("types", [])
            }
            
            activities_details.append(place_data)
            print(f"  ✓ {google_place['name']} ({activity_input.type}) - {estimated_duration} min")
        
        # Optimize sequence (simple: by proximity for now)
        # In production, use TSP algorithm or Google Routes API
        optimized_activities = self._optimize_sequence(activities_details)
        
        # Create plan in database
        db_plan = Plan(
            plan_id=plan_id,
            user_id=plan_request.user_id,
            name=plan_request.name,
            start_time=plan_request.start_time,
            status="draft"
        )
        self.db.add(db_plan)
        self.db.flush()  # Get the ID
        
        # Create activities with timing
        current_time = plan_request.start_time
        plan_activities_response = []
        total_time_minutes = 0
        total_travel_time = 0
        total_activity_time = 0
        
        for i, activity in enumerate(optimized_activities):
            # Calculate transport from previous location
            transport = None
            transport_options = None
            
            if i > 0:
                prev_activity = optimized_activities[i - 1]
                
                # Obtener todas las opciones de transporte
                transport_options = self.get_all_transport_options(
                    prev_activity["latitude"],
                    prev_activity["longitude"],
                    activity["latitude"],
                    activity["longitude"]
                )
                
                # Sugerir el mejor modo basado en distancia
                suggested_mode = self._suggest_transport_mode(
                    transport_options["transit"]["distance_km"]
                )
                
                # Usar el tiempo del modo sugerido
                travel_time = transport_options[suggested_mode]["duration_minutes"]
                
                transport = {
                    "suggested_mode": suggested_mode,
                    "duration_minutes": travel_time,
                    "distance_km": transport_options[suggested_mode]["distance_km"],
                    "all_options": transport_options,
                    "route": [
                        {"lat": prev_activity["latitude"], "lon": prev_activity["longitude"]},
                        {"lat": activity["latitude"], "lon": activity["longitude"]}
                    ]
                }
                
                # Add travel time
                current_time += timedelta(minutes=travel_time)
                total_time_minutes += travel_time
                total_travel_time += travel_time
            
            activity_start = current_time
            activity_duration = activity["estimated_duration"]
            activity_end = current_time + timedelta(minutes=activity_duration)
            
            # Save to database
            db_activity = PlanActivity(
                plan_id=db_plan.id,
                activity_id=activity["id"],
                activity_type=activity["type"],
                activity_name=activity["name"],
                activity_category=activity.get("category"),  # Guardar categoría
                sequence=i,
                start_time=activity_start,
                end_time=activity_end,
                latitude=activity["latitude"],
                longitude=activity["longitude"],
                transport=transport,
                metadata={
                    "rating": activity.get("rating"),
                    "types": activity.get("types", []),
                    "source": activity.get("source")
                }
            )
            self.db.add(db_activity)
            
            # Add to response
            plan_activities_response.append({
                "sequence": i + 1,
                "activity_name": activity["name"],
                "activity_type": activity["type"],
                "start_time": activity_start.isoformat(),
                "end_time": activity_end.isoformat(),
                "duration_minutes": activity_duration,
                "location": {"lat": activity["latitude"], "lon": activity["longitude"]},
                "transport_to_here": transport
            })
            
            # Move to next activity
            current_time = activity_end
            total_time_minutes += activity_duration
            total_activity_time += activity_duration
        
        # Update plan with end time and total time
        db_plan.end_time = current_time
        db_plan.total_estimated_time = total_time_minutes
        
        self.db.commit()
        self.db.refresh(db_plan)
        
        return {
            "plan_id": plan_id,
            "name": plan_request.name,
            "user_id": plan_request.user_id,
            "start_time": plan_request.start_time.isoformat(),
            "end_time": current_time.isoformat(),
            "activities": plan_activities_response,
            "summary": {
                "total_activities": len(plan_activities_response),
                "total_time_minutes": total_time_minutes,
                "total_time_formatted": f"{total_time_minutes // 60}h {total_time_minutes % 60}min",
                "total_activity_time_minutes": total_activity_time,
                "total_travel_time_minutes": total_travel_time,
                "activity_time_formatted": f"{total_activity_time // 60}h {total_activity_time % 60}min",
                "travel_time_formatted": f"{total_travel_time // 60}h {total_travel_time % 60}min"
            },
            "status": "draft",
            "created_at": db_plan.created_at.isoformat()
        }
    
    def _optimize_sequence(self, activities: List[Dict]) -> List[Dict]:
        """
        Optimizar secuencia de actividades por proximidad
        Algoritmo Greedy: Nearest Neighbor
        """
        if not activities:
            return []
        
        if len(activities) == 1:
            return activities
        
        # Algoritmo de vecino más cercano
        result = []
        remaining = activities.copy()
        
        # Empezar con el primer lugar
        current = remaining.pop(0)
        result.append(current)
        
        # Ir al lugar más cercano sucesivamente
        while remaining:
            nearest = min(
                remaining,
                key=lambda x: self.rec_service.calculate_distance(
                    current["latitude"], current["longitude"],
                    x["latitude"], x["longitude"]
                )
            )
            result.append(nearest)
            remaining.remove(nearest)
            current = nearest
        
        return result
    
    def _suggest_transport_mode(self, distance: float) -> str:
        """
        Sugerir modo de transporte basado en distancia
        Retorna modos válidos de Google Directions API
        """
        if distance < 1:
            return "walking"
        elif distance < 5:
            return "transit"  # Transporte público (bus/metro)
        else:
            return "transit"  # Transporte público (metro)
    
    def get_plan_by_id(self, plan_id: str) -> Optional[Dict[str, Any]]:
        """Obtener un plan por su ID"""
        plan = self.db.query(Plan).filter(Plan.plan_id == plan_id).first()
        
        if not plan:
            return None
        
        activities = self.db.query(PlanActivity).filter(
            PlanActivity.plan_id == plan.id
        ).order_by(PlanActivity.sequence).all()
        
        # Calcular tiempos
        total_activity_time = 0
        total_travel_time = 0
        
        plan_activities_response = []
        for act in activities:
            duration = int((act.end_time - act.start_time).total_seconds() / 60)
            total_activity_time += duration
            
            transport = None
            if act.transport:
                transport = act.transport
                if isinstance(transport, dict) and 'duration_minutes' in transport:
                    total_travel_time += transport['duration_minutes']
            
            plan_activities_response.append({
                "sequence": act.sequence + 1,
                "activity_name": act.activity_name,
                "activity_type": act.activity_type,
                "start_time": act.start_time.isoformat(),
                "end_time": act.end_time.isoformat(),
                "duration_minutes": duration,
                "location": {"lat": act.latitude, "lon": act.longitude},
                "transport_to_here": transport
            })
        
        total_time = plan.total_estimated_time or (total_activity_time + total_travel_time)
        
        return {
            "plan_id": plan.plan_id,
            "name": plan.name,
            "user_id": plan.user_id,
            "start_time": plan.start_time.isoformat(),
            "end_time": plan.end_time.isoformat() if plan.end_time else None,
            "activities": plan_activities_response,
            "summary": {
                "total_activities": len(plan_activities_response),
                "total_time_minutes": total_time,
                "total_time_formatted": f"{total_time // 60}h {total_time % 60}min",
                "total_activity_time_minutes": total_activity_time,
                "total_travel_time_minutes": total_travel_time,
                "activity_time_formatted": f"{total_activity_time // 60}h {total_activity_time % 60}min",
                "travel_time_formatted": f"{total_travel_time // 60}h {total_travel_time % 60}min"
            },
            "status": plan.status,
            "created_at": plan.created_at.isoformat()
        }
    
    def get_user_plans(self, user_id: str, status_filter: Optional[str] = None) -> List[Dict[str, Any]]:
        """Obtener todos los planes de un usuario"""
        query = self.db.query(Plan).filter(Plan.user_id == user_id)
        
        if status_filter:
            query = query.filter(Plan.status == status_filter)
        
        plans = query.order_by(Plan.created_at.desc()).all()
        
        return [self.get_plan_by_id(plan.plan_id) for plan in plans]
    
    def update_plan(self, plan_id: str, plan_update: PlanUpdateRequest) -> Optional[Dict[str, Any]]:
        """Actualizar un plan"""
        plan = self.db.query(Plan).filter(Plan.plan_id == plan_id).first()
        
        if not plan:
            return None
        
        if plan_update.name is not None:
            plan.name = plan_update.name
        
        if plan_update.status is not None:
            plan.status = plan_update.status
        
        self.db.commit()
        
        return self.get_plan_by_id(plan_id)
    
    def delete_plan(self, plan_id: str) -> bool:
        """Eliminar un plan"""
        plan = self.db.query(Plan).filter(Plan.plan_id == plan_id).first()
        
        if not plan:
            return False
        
        self.db.delete(plan)
        self.db.commit()
        return True
    
    def complete_plan(
        self, 
        plan_id: str,
        activity_ratings: Optional[Dict[str, int]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Completar un plan y registrar automáticamente todos los lugares visitados
        
        Args:
            plan_id: ID del plan
            activity_ratings: Dict con {activity_id: rating} opcional
            
        Returns:
            Plan actualizado con status "completed"
        """
        from app.services.user_service import UserService
        
        plan = self.db.query(Plan).filter(Plan.plan_id == plan_id).first()
        
        if not plan:
            return None
        
        if plan.status == "completed":
            print(f"⚠️ Plan {plan_id} ya está completado")
            return self.get_plan_by_id(plan_id)
        
        # Marcar plan como completado
        plan.status = "completed"
        plan.updated_at = datetime.utcnow()
        
        # Registrar cada actividad como lugar visitado
        user_service = UserService(self.db)
        user = user_service.get_user_by_id(plan.user_id)
        
        if not user:
            print(f"⚠️ Usuario {plan.user_id} no encontrado")
            self.db.commit()
            return self.get_plan_by_id(plan_id)
        
        visited_count = 0
        print(f"🔄 Procesando {len(plan.activities)} actividades del plan...")
        
        for activity in plan.activities:
            print(f"  🔍 Actividad: {activity.activity_name} (type: {activity.activity_type}, category: {activity.activity_category})")
            
            # Solo registrar lugares (no eventos)
            if activity.activity_type == "place":
                # Obtener rating si se proporcionó
                rating = None
                if activity_ratings and activity.activity_id in activity_ratings:
                    rating = activity_ratings[activity.activity_id]
                
                # Crear objeto de lugar visitado
                visited_place = VisitedPlace(
                    place_id=activity.activity_id,
                    place_name=activity.activity_name,
                    rating=rating,
                    category=activity.activity_category
                )
                
                print(f"  📝 Intentando registrar: {activity.activity_name}")
                
                # Registrar en el perfil del usuario
                try:
                    result = user_service.add_visited_place(plan.user_id, visited_place)
                    if result:
                        visited_count += 1
                        print(f"  ✅ Registrado exitosamente: {activity.activity_name} ({activity.activity_category})")
                    else:
                        print(f"  ❌ Error: add_visited_place retornó None para {activity.activity_name}")
                except Exception as e:
                    print(f"  ❌ Error registrando {activity.activity_name}: {str(e)}")
                    import traceback
                    traceback.print_exc()
            else:
                print(f"  ⏭️ Saltando actividad tipo '{activity.activity_type}' (no es 'place')")
        
        print(f"📊 Total procesado: {visited_count} de {len(plan.activities)} actividades")
        self.db.commit()
        
        print(f"🎉 Plan completado: {plan.name}")
        print(f"📍 {visited_count} lugar(es) registrados en el perfil de {user.name}")
        print(f"⭐ Categorías favoritas actualizadas: {user.favorite_categories}")
        
        return self.get_plan_by_id(plan_id)
