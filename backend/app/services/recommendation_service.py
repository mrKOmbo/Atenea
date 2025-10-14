from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Dict, Any, Optional
import math
import json
import requests

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False

from app.models.recommendation import Recommendation
from app.core.config import settings


class RecommendationService:
    # Mapeo de preferencias a tipos de Google Places
    PREFERENCE_TO_GOOGLE_TYPE = {
        "museums": "museum",
        "parks": "park",
        "restaurants": "restaurant",
        "cafes": "cafe",
        "bars": "bar",
        "nightlife": "night_club",
        "shopping": "shopping_mall",
        "cultural": "tourist_attraction",
        "events": "tourist_attraction",
        "landmarks": "tourist_attraction",
        "theaters": "movie_theater",
        "gyms": "gym",
        "spas": "spa",
        "hotels": "lodging"
    }
    
    def __init__(self, db: Session):
        self.db = db
        self.google_maps_api_key = settings.GOOGLE_MAPS_API_KEY
        
        # Inicializar Gemini si está configurado
        self.gemini_model = None
        if GEMINI_AVAILABLE and settings.AI_PROVIDER == "gemini" and settings.GOOGLE_GEMINI_API_KEY:
            try:
                genai.configure(api_key=settings.GOOGLE_GEMINI_API_KEY)
                # Usar gemini-2.5-flash (modelo actual gratuito)
                self.gemini_model = genai.GenerativeModel('gemini-2.5-flash')
                print("✓ Gemini IA inicializado correctamente")
            except Exception as e:
                print(f"⚠ Error inicializando Gemini (continuando sin IA): {e}")
                self.gemini_model = None
    
    def calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calcular distancia en km usando fórmula de Haversine"""
        R = 6371  # Radio de la Tierra en km
        
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (math.sin(dlat / 2) * math.sin(dlat / 2) +
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
             math.sin(dlon / 2) * math.sin(dlon / 2))
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance = R * c
        
        return round(distance, 2)
    
    def estimate_travel_time(self, distance: float) -> int:
        """Estimar tiempo de viaje en transporte público (minutos)"""
        # Aproximación: 20 km/h promedio en transporte público CDMX
        avg_speed = 20  # km/h
        time_hours = distance / avg_speed
        time_minutes = int(time_hours * 60)
        
        # Add 10 minutes for waiting/transfers
        return time_minutes + 10
    
    def search_google_places(
        self,
        latitude: float,
        longitude: float,
        place_type: str,
        radius: int = 5000,
        keyword: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Buscar lugares reales usando Google Places API
        
        Args:
            latitude: Latitud del usuario
            longitude: Longitud del usuario
            place_type: Tipo de lugar (museum, park, restaurant, etc.)
            radius: Radio de búsqueda en metros (default: 5km)
            keyword: Keyword específico (ej: "japanese", "sushi")
        
        Returns:
            Lista de lugares encontrados
        """
        if not self.google_maps_api_key:
            print("⚠ Google Maps API Key no configurada")
            return []
        
        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        
        params = {
            "location": f"{latitude},{longitude}",
            "radius": radius,
            "type": place_type,
            "key": self.google_maps_api_key,
            "language": "es"
        }
        
        # Agregar keyword si se proporciona
        if keyword:
            params["keyword"] = keyword
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data.get("status") != "OK":
                print(f"⚠ Google Places API error: {data.get('status')}")
                return []
            
            places = []
            for result in data.get("results", [])[:10]:  # Top 10
                place_data = {
                    "place_id": result.get("place_id"),
                    "name": result.get("name"),
                    "type": place_type,
                    "latitude": result["geometry"]["location"]["lat"],
                    "longitude": result["geometry"]["location"]["lng"],
                    "rating": result.get("rating"),
                    "user_ratings_total": result.get("user_ratings_total", 0),
                    "address": result.get("vicinity"),
                    "photo_reference": result.get("photos", [{}])[0].get("photo_reference") if result.get("photos") else None,
                    "is_open": result.get("opening_hours", {}).get("open_now"),
                    "price_level": result.get("price_level")
                }
                places.append(place_data)
            
            return places
            
        except requests.exceptions.RequestException as e:
            print(f"⚠ Error llamando a Google Places API: {e}")
            return []
        except Exception as e:
            print(f"⚠ Error procesando respuesta de Google Places: {e}")
            return []
    
    def generate_recommendations(
        self,
        user_id: str,
        latitude: float,
        longitude: float,
        preferences: List[str],
        user_context: Optional[Dict] = None
    ) -> List[Dict[str, Any]]:
        """
        Generar recomendaciones personalizadas usando Google Places API
        Busca lugares reales en tiempo real según las preferencias del usuario
        
        Args:
            user_id: ID del usuario
            latitude: Latitud actual
            longitude: Longitud actual
            preferences: Lista de preferencias
            user_context: Contexto del usuario (nacionalidad, historial, etc.)
        """
        recommendations = []
        
        # Radio de búsqueda: 5km
        search_radius_meters = 5000
        
        # Personalizar preferencias basadas en el perfil del usuario
        if user_context:
            preferences = self._personalize_preferences(preferences, user_context)
        
        print(f"🔍 Buscando lugares para preferencias: {preferences}")
        
        # Buscar lugares en Google Places API para cada preferencia
        for preference in preferences:
            # Mapear preferencia a tipo de Google Places
            google_type = self.PREFERENCE_TO_GOOGLE_TYPE.get(preference)
            
            if not google_type:
                print(f"⚠ Preferencia '{preference}' no mapeada a tipo de Google")
                continue
            
            # Determinar keyword según nacionalidad y preferencia
            keyword = self._get_search_keyword(preference, user_context)
            
            # Buscar lugares de este tipo con keyword específico
            places = self.search_google_places(
                latitude=latitude,
                longitude=longitude,
                place_type=google_type,
                radius=search_radius_meters,
                keyword=keyword
            )
            
            if keyword:
                print(f"  ✓ Encontrados {len(places)} lugares tipo '{google_type}' (keyword: '{keyword}')")
            else:
                print(f"  ✓ Encontrados {len(places)} lugares tipo '{google_type}'")
            
            # Sistema de fallback: Si encuentra pocos resultados con keyword, buscar sin keyword
            MIN_RESULTS = 3
            specific_count = len(places)  # Guardar cuántos eran específicos
            
            if keyword and len(places) < MIN_RESULTS:
                print(f"  ⚠️ Pocos resultados con keyword específico, buscando alternativas genéricas...")
                
                # Buscar sin keyword (genérico)
                generic_places = self.search_google_places(
                    latitude=latitude,
                    longitude=longitude,
                    place_type=google_type,
                    radius=search_radius_meters,
                    keyword=None  # Sin keyword
                )
                
                # Combinar resultados (evitar duplicados por place_id)
                existing_ids = {p["place_id"] for p in places}
                for generic_place in generic_places:
                    if generic_place["place_id"] not in existing_ids:
                        places.append(generic_place)
                        existing_ids.add(generic_place["place_id"])
                
                print(f"  ✓ Total con alternativas: {len(places)} lugares (fallback aplicado)")
            
            # Marcar cuáles son específicos (los primeros) y cuáles son fallback (los agregados después)
            specific_place_ids = {places[i]["place_id"] for i in range(min(specific_count, len(places)))}
            
            # Procesar cada lugar encontrado
            for place in places:
                distance = self.calculate_distance(
                    latitude, longitude,
                    place["latitude"], place["longitude"]
                )
                time_estimate = self.estimate_travel_time(distance)
                
                # Calcular score basado en rating y distancia
                rating = place.get("rating") or 3.5
                score = self._calculate_score(rating, distance)
                
                # Boost score si tiene muchas reseñas
                if place.get("user_ratings_total", 0) > 100:
                    score = min(1.0, score + 0.1)
                
                # Determinar si es resultado específico o fallback
                is_specific_match = place["place_id"] in specific_place_ids if keyword else True
                
                # Personalizar score basado en el usuario
                if user_context:
                    score = self._personalize_score(
                        score, place, preference, user_context, is_specific_match
                    )
                
                recommendations.append({
                    "name": place["name"],
                    "type": preference,
                    "location": {"lat": place["latitude"], "lon": place["longitude"]},
                    "description": f"Lugar popular en {place.get('address', 'la zona')}",
                    "rating": rating,
                    "distance": distance,
                    "time_estimate": time_estimate,
                    "score": score,
                    "reason": f"Lugar recomendado cerca de tu ubicación",
                    "is_fallback": not is_specific_match if keyword else False,
                    "metadata": {
                        "place_id": place["place_id"],
                        "address": place.get("address"),
                        "user_ratings_total": place.get("user_ratings_total", 0),
                        "price_level": place.get("price_level"),
                        "is_open": place.get("is_open"),
                        "photo_reference": place.get("photo_reference"),
                        "source": "google_places",
                        "matched_keyword": keyword if is_specific_match else None
                    }
                })
        
        # Eliminar duplicados por place_id
        seen_places = set()
        unique_recommendations = []
        for rec in recommendations:
            place_id = rec["metadata"]["place_id"]
            if place_id not in seen_places:
                seen_places.add(place_id)
                unique_recommendations.append(rec)
        
        recommendations = unique_recommendations
        
        # Ordenar por score (mayor a menor)
        recommendations.sort(key=lambda x: x["score"], reverse=True)
        
        # Mejorar razones con Gemini IA
        if self.gemini_model:
            recommendations = self._enhance_with_gemini(recommendations, preferences)
        
        # Save recommendations to database
        for rec in recommendations[:15]:  # Save top 15
            db_rec = Recommendation(
                user_id=user_id,
                item_id=rec["metadata"].get("place_id") or rec["metadata"].get("event_id"),
                item_type="place" if "place_id" in rec["metadata"] else "event",
                score=rec["score"],
                distance=rec["distance"],
                time_estimate=rec["time_estimate"],
                reason=rec["reason"],
                extra_data=rec["metadata"]
            )
            self.db.add(db_rec)
        
        self.db.commit()
        
        return recommendations[:15]
    
    def _calculate_score(self, rating: float, distance: float) -> float:
        """
        Calcular score de recomendación basado en rating y distancia
        Score entre 0 y 1
        """
        # Normalize rating (0-5 scale to 0-1)
        rating_score = rating / 5.0
        
        # Normalize distance (closer is better)
        # Max useful distance is 15km
        distance_score = max(0, 1 - (distance / 15))
        
        # Weighted average: 60% rating, 40% distance
        score = (rating_score * 0.6) + (distance_score * 0.4)
        
        return round(score, 2)
    
    def _enhance_with_gemini(self, recommendations: List[Dict], user_preferences: List[str]) -> List[Dict]:
        """
        Mejora las recomendaciones usando Google Gemini para generar razones personalizadas
        """
        if not self.gemini_model or not recommendations:
            return recommendations
        
        try:
            # Preparar información de los top 5 lugares
            places_info = []
            for rec in recommendations[:5]:
                places_info.append({
                    "nombre": rec["name"],
                    "tipo": rec["type"],
                    "descripcion": rec.get("description", "")[:100],
                    "rating": rec.get("rating"),
                    "distancia_km": rec.get("distance")
                })
            
            # Crear prompt para Gemini
            prompt = f"""
Eres un asistente turístico experto en Ciudad de México.

Usuario interesado en: {', '.join(user_preferences)}

Lugares recomendados:
{json.dumps(places_info, indent=2, ensure_ascii=False)}

Tarea: Para cada lugar, genera una razón breve y entusiasta (máximo 35 palabras) explicando 
por qué es perfecto para este usuario.

Responde SOLO en formato JSON válido:
{{
  "nombre_lugar_1": "razón personalizada",
  "nombre_lugar_2": "razón personalizada"
}}

No agregues texto adicional, solo el JSON.
"""
            
            # Llamar a Gemini
            response = self.gemini_model.generate_content(prompt)
            text = response.text.strip()
            
            # Limpiar y extraer JSON de la respuesta
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0].strip()
            elif "```" in text:
                text = text.split("```")[1].split("```")[0].strip()
            
            # Parsear JSON
            enhanced_reasons = json.loads(text)
            
            # Actualizar recomendaciones con razones mejoradas
            for rec in recommendations:
                if rec["name"] in enhanced_reasons:
                    rec["reason"] = enhanced_reasons[rec["name"]]
            
            print(f"✓ Gemini mejoró {len(enhanced_reasons)} recomendaciones")
            
        except Exception as e:
            print(f"Error usando Gemini (continuando sin IA): {str(e)}")
        
        return recommendations
    
    def _get_search_keyword(
        self,
        preference: str,
        user_context: Optional[Dict]
    ) -> Optional[str]:
        """
        Determinar keyword de búsqueda según nacionalidad y preferencia
        
        Args:
            preference: Tipo de preferencia (restaurants, cafes, etc.)
            user_context: Contexto del usuario con nacionalidad
            
        Returns:
            Keyword para búsqueda o None si no aplica
        """
        if not user_context:
            return None
        
        nationality = user_context.get("nationality", "").lower()
        
        # Keywords específicos por nacionalidad y preferencia
        nationality_keywords = {
            "japan": {
                "restaurants": "japanese restaurant sushi ramen yakitori",
                "cafes": "japanese cafe matcha",
                "bars": "japanese bar izakaya sake",
                "nightlife": "japanese izakaya sake bar",
                "museums": "japanese art samurai",
                "cultural": "japanese culture zen garden",
                "shopping": "japanese store anime manga"
            },
            "italy": {
                "restaurants": "italian restaurant pizza pasta trattoria",
                "cafes": "italian cafe gelato espresso",
                "bars": "italian bar wine aperitivo",
                "nightlife": "italian wine bar",
                "museums": "renaissance italian art",
                "cultural": "roman architecture italian heritage",
                "shopping": "italian fashion design"
            },
            "france": {
                "restaurants": "french restaurant bistro brasserie",
                "cafes": "french cafe patisserie croissant",
                "bars": "french wine bar champagne",
                "nightlife": "french wine bar cabaret",
                "museums": "french art impressionist louvre",
                "cultural": "french architecture palace",
                "shopping": "french boutique parfum"
            },
            "spain": {
                "restaurants": "spanish restaurant tapas paella",
                "cafes": "spanish cafe churros",
                "bars": "spanish bar tapas wine",
                "nightlife": "spanish bar flamenco",
                "museums": "spanish art gaudi",
                "cultural": "spanish heritage flamenco",
                "shopping": "spanish market"
            },
            "china": {
                "restaurants": "chinese restaurant dim sum noodles",
                "cafes": "chinese tea house bubble tea",
                "bars": "chinese bar karaoke",
                "nightlife": "chinese karaoke bar",
                "museums": "chinese art calligraphy",
                "cultural": "chinese temple kung fu",
                "shopping": "chinese market"
            },
            "india": {
                "restaurants": "indian restaurant curry tandoori biryani",
                "cafes": "indian cafe chai",
                "bars": "indian bar",
                "nightlife": "indian bar club",
                "museums": "indian art temple",
                "cultural": "indian temple yoga",
                "shopping": "indian market spices"
            },
            "mexico": {
                "restaurants": "mexican restaurant tacos mole",
                "cafes": "mexican cafe pan dulce",
                "bars": "mexican bar mezcal tequila",
                "nightlife": "mexican bar mariachi",
                "museums": "mexican art frida kahlo aztec",
                "cultural": "mexican heritage pyramids",
                "shopping": "mexican market artesanías"
            },
            "usa": {
                "restaurants": "american restaurant burger bbq steakhouse",
                "cafes": "american cafe diner coffee",
                "bars": "american bar brewery craft beer",
                "nightlife": "american club bar",
                "museums": "american art contemporary",
                "cultural": "american heritage",
                "shopping": "american mall outlet"
            },
            "korea": {
                "restaurants": "korean restaurant bbq kimchi bibimbap",
                "cafes": "korean cafe bingsu",
                "bars": "korean bar soju karaoke",
                "nightlife": "korean karaoke noraebang bar",
                "museums": "korean art k-pop",
                "cultural": "korean temple hanbok",
                "shopping": "korean beauty k-pop"
            },
            "germany": {
                "restaurants": "german restaurant beer garden schnitzel",
                "cafes": "german cafe bakery",
                "bars": "german bar beer garden",
                "nightlife": "german beer hall bar",
                "museums": "german art bauhaus",
                "cultural": "german heritage castle",
                "shopping": "german market christmas"
            },
            "brazil": {
                "restaurants": "brazilian restaurant churrascaria feijoada",
                "cafes": "brazilian cafe acai",
                "bars": "brazilian bar caipirinha",
                "nightlife": "brazilian bar samba",
                "museums": "brazilian art",
                "cultural": "brazilian samba carnival",
                "shopping": "brazilian market"
            }
        }
        
        # Obtener keyword si existe
        if nationality in nationality_keywords:
            keywords_dict = nationality_keywords[nationality]
            keyword = keywords_dict.get(preference)
            if keyword:
                print(f"🔍 Usando keyword: '{keyword}' (nacionalidad: {nationality})")
                return keyword
        
        return None
    
    def _personalize_preferences(
        self, 
        preferences: List[str], 
        user_context: Dict
    ) -> List[str]:
        """
        Personalizar preferencias basadas en el perfil del usuario
        
        Ejemplo: Si usuario es japonés, agregar búsqueda de restaurantes japoneses
        """
        personalized = preferences.copy()
        nationality = user_context.get("nationality", "").lower()
        favorite_categories = user_context.get("favorite_categories", [])
        
        # Agregar preferencias basadas en nacionalidad
        nationality_preferences = {
            "japan": ["restaurants"],  # Buscar restaurantes japoneses
            "italy": ["restaurants"],  # Restaurantes italianos
            "france": ["restaurants", "cafes"],
            "spain": ["restaurants", "bars"],
            "china": ["restaurants"],
            "india": ["restaurants"],
            "usa": ["restaurants", "bars"]
        }
        
        if nationality in nationality_preferences:
            for pref in nationality_preferences[nationality]:
                if pref not in personalized:
                    personalized.append(pref)
                    print(f"🌍 Agregando '{pref}' por nacionalidad: {nationality}")
        
        # Agregar categorías favoritas del historial
        for category in favorite_categories[:3]:  # Top 3 favoritas
            if category not in personalized:
                personalized.append(category)
                print(f"⭐ Agregando '{category}' (categoría favorita del usuario)")
        
        return personalized
    
    def _personalize_score(
        self, 
        base_score: float, 
        place: Dict, 
        preference: str,
        user_context: Dict,
        is_specific_match: bool = True
    ) -> float:
        """
        Ajustar score basado en el perfil del usuario
        
        Factores de personalización:
        - Nacionalidad (ej: japonés → boost lugares japoneses)
        - Historial de visitas (boost categorías similares)
        - Edad (ej: jóvenes → nightlife, mayores → cultura)
        - Rasgos de personalidad
        - is_specific_match: Si es True, fue encontrado con keyword específico. Si es False, es fallback genérico.
        """
        score = base_score
        nationality = user_context.get("nationality", "").lower()
        age = user_context.get("age")
        favorite_categories = user_context.get("favorite_categories", [])
        personality = user_context.get("personality_traits", {})
        
        place_name = place.get("name", "").lower()
        place_types = place.get("types", [])
        
        # 1. BOOST POR NACIONALIDAD
        # Si el lugar tiene relación con la nacionalidad del usuario
        nationality_keywords = {
            "japan": ["japanese", "japan", "sushi", "ramen", "yakitori", "izakaya", "japonés", "japón"],
            "italy": ["italian", "italy", "pizza", "pasta", "italiano", "italia"],
            "france": ["french", "france", "francés", "francia", "bistro", "brasserie"],
            "spain": ["spanish", "spain", "español", "españa", "tapas", "paella"],
            "china": ["chinese", "china", "chino", "dim sum", "noodles"],
            "india": ["indian", "india", "indio", "curry", "tandoori"],
            "mexico": ["mexican", "mexico", "mexicano", "méxico", "taquería", "cantina"],
            "usa": ["american", "burger", "bbq", "steakhouse"]
        }
        
        if nationality in nationality_keywords:
            keywords = nationality_keywords[nationality]
            if any(keyword in place_name for keyword in keywords):
                # Si es match específico (encontrado con keyword), dar boost completo
                # Si es fallback, dar boost solo si el nombre coincide (match natural)
                if is_specific_match:
                    score = min(1.0, score + 0.25)  # +25% boost
                    print(f"  🌍 +25% boost (match nacionalidad: {nationality})")
                else:
                    score = min(1.0, score + 0.15)  # +15% boost reducido para fallback
                    print(f"  🌍 +15% boost (match nacionalidad en fallback: {nationality})")
        
        # 2. BOOST POR CATEGORÍAS FAVORITAS
        # Si el preference coincide con categorías favoritas del usuario
        if preference in favorite_categories:
            score = min(1.0, score + 0.15)  # +15% boost
            print(f"  ⭐ +15% boost (categoría favorita: {preference})")
        
        # 3. BOOST POR EDAD
        if age:
            if age < 30:
                # Jóvenes: boost nightlife, cafes, modern
                if preference in ["nightlife", "bars", "cafes"]:
                    score = min(1.0, score + 0.10)
                    print(f"  🎉 +10% boost (perfil joven)")
            elif age > 50:
                # Mayores: boost cultura, museos, naturaleza
                if preference in ["museums", "cultural", "parks"]:
                    score = min(1.0, score + 0.10)
                    print(f"  🎨 +10% boost (perfil cultural)")
        
        # 4. BOOST POR PERSONALIDAD
        if personality:
            # Culture lover → museos, galerías
            if personality.get("culture_lover", 0) > 0.7:
                if preference in ["museums", "cultural", "landmarks"]:
                    score = min(1.0, score + 0.12)
                    print(f"  🎭 +12% boost (culture lover)")
            
            # Foodie → restaurantes, cafes
            if personality.get("foodie", 0) > 0.7:
                if preference in ["restaurants", "cafes", "bars"]:
                    score = min(1.0, score + 0.12)
                    print(f"  🍽️ +12% boost (foodie)")
            
            # Nature lover → parques
            if personality.get("nature_lover", 0) > 0.7:
                if preference == "parks":
                    score = min(1.0, score + 0.12)
                    print(f"  🌳 +12% boost (nature lover)")
        
        # 5. PENALIZACIÓN POR LUGARES YA VISITADOS
        visited_count = user_context.get("visited_count", 0)
        if visited_count > 10:
            # Usuario experimentado, priorizar lugares menos conocidos
            if place.get("user_ratings_total", 0) > 5000:
                score = score * 0.95  # -5% para lugares muy populares
                print(f"  📉 -5% (usuario experimentado, lugar muy conocido)")
        
        return round(score, 2)
