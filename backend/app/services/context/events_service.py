"""
Servicio de Eventos de la Ciudad
PLACEHOLDER - A implementar por el otro desarrollador con web scraping

Este servicio debe obtener eventos actuales en CDMX mediante:
- Web scraping de sitios de eventos
- APIs de eventos (Eventbrite, etc.)
- Fuentes locales
"""
from typing import List, Dict, Optional
from datetime import datetime, date


class EventsService:
    """
    Servicio para obtener eventos en la ciudad
    
    El otro desarrollador debe implementar:
    - Web scraping de sitios de eventos
    - Integración con APIs de eventos
    - Base de datos de eventos
    """
    
    def __init__(self):
        self.cache = {}
        self.cache_duration = 3600  # 1 hora
    
    def get_current_events(
        self, 
        lat: float, 
        lon: float,
        radius_km: float = 5.0,
        target_date: Optional[date] = None
    ) -> List[Dict]:
        """
        Obtener eventos actuales cerca de una ubicación
        
        IMPLEMENTACIÓN PENDIENTE POR OTRO DESARROLLADOR
        
        Args:
            lat: Latitud
            lon: Longitud
            radius_km: Radio de búsqueda en km
            target_date: Fecha objetivo (default: hoy)
            
        Returns:
            Lista de eventos:
            [
                {
                    "event_id": "evt_123",
                    "name": "Concierto de Rock",
                    "category": "music",
                    "location": {
                        "lat": 19.4326,
                        "lon": -99.1332,
                        "address": "Palacio de Bellas Artes"
                    },
                    "datetime": "2024-12-15T20:00:00",
                    "end_datetime": "2024-12-15T23:00:00",
                    "impact": "high",  # high, medium, low
                    "affects_traffic": True,
                    "expected_attendance": 5000,
                    "price": "paid",  # paid, free
                    "source": "eventbrite",
                    "url": "https://..."
                }
            ]
        """
        # TODO: Implementar web scraping aquí
        # El otro desarrollador debe reemplazar esto
        
        print("⚠️ EventsService: Usando eventos de ejemplo (implementar web scraping)")
        return self._get_mock_events(target_date)
    
    def _get_mock_events(self, target_date: Optional[date] = None) -> List[Dict]:
        """
        Eventos de ejemplo para testing
        El otro desarrollador debe eliminar esto y poner scraping real
        """
        if target_date is None:
            target_date = date.today()
        
        # Eventos mock para demo
        mock_events = [
            {
                "event_id": "evt_001",
                "name": "Festival Cultural del Centro Histórico",
                "category": "cultural",
                "location": {
                    "lat": 19.4326,
                    "lon": -99.1332,
                    "address": "Zócalo, Centro Histórico"
                },
                "datetime": f"{target_date}T10:00:00",
                "end_datetime": f"{target_date}T22:00:00",
                "impact": "high",
                "affects_traffic": True,
                "expected_attendance": 10000,
                "price": "free",
                "source": "mock",
                "url": "https://example.com",
                "description": "Gran festival cultural con actividades para toda la familia"
            },
            {
                "event_id": "evt_002",
                "name": "Concierto en el Auditorio Nacional",
                "category": "music",
                "location": {
                    "lat": 19.4260,
                    "lon": -99.1912,
                    "address": "Auditorio Nacional"
                },
                "datetime": f"{target_date}T20:00:00",
                "end_datetime": f"{target_date}T23:00:00",
                "impact": "medium",
                "affects_traffic": True,
                "expected_attendance": 5000,
                "price": "paid",
                "source": "mock",
                "url": "https://example.com",
                "description": "Concierto de artista internacional"
            }
        ]
        
        return mock_events
    
    def get_traffic_affecting_events(
        self, 
        lat: float, 
        lon: float,
        radius_km: float = 10.0
    ) -> List[Dict]:
        """
        Obtener solo eventos que afectan tráfico
        
        Returns:
            Lista de eventos que generan tráfico/cierres
        """
        all_events = self.get_current_events(lat, lon, radius_km)
        return [e for e in all_events if e.get("affects_traffic", False)]
    
    def adjust_recommendations_by_events(
        self, 
        places: list, 
        events: List[Dict],
        user_lat: float,
        user_lon: float
    ) -> list:
        """
        Ajustar recomendaciones según eventos en la ciudad
        
        Args:
            places: Lista de lugares recomendados
            events: Lista de eventos actuales
            user_lat: Latitud del usuario
            user_lon: Longitud del usuario
            
        Returns:
            Lista ajustada con contexto de eventos
        """
        if not events:
            return places
        
        from app.services.recommendation_service import RecommendationService
        rec_service = RecommendationService(None)
        
        for place in places:
            place_lat = place.get("location", {}).get("lat")
            place_lon = place.get("location", {}).get("lon")
            
            if not place_lat or not place_lon:
                continue
            
            # Verificar eventos cercanos al lugar
            nearby_events = []
            for event in events:
                event_lat = event.get("location", {}).get("lat")
                event_lon = event.get("location", {}).get("lon")
                
                if not event_lat or not event_lon:
                    continue
                
                distance = rec_service.calculate_distance(
                    place_lat, place_lon, event_lat, event_lon
                )
                
                if distance < 1.0:  # Menos de 1km
                    nearby_events.append(event)
            
            # Ajustar según eventos cercanos
            if nearby_events:
                high_impact = any(e.get("impact") == "high" for e in nearby_events)
                
                if high_impact:
                    # Eventos grandes pueden ser positivo (atracción) o negativo (tráfico)
                    event_names = [e["name"] for e in nearby_events]
                    place["nearby_events"] = nearby_events
                    place["event_info"] = f"🎉 Cerca de: {', '.join(event_names[:2])}"
                    
                    # Si el evento afecta tráfico, reducir score
                    if any(e.get("affects_traffic") for e in nearby_events):
                        place["score"] = place.get("score", 0.5) * 0.9
                        place["traffic_warning"] = "⚠️ Posible tráfico por evento cercano"
        
        # Re-ordenar
        places.sort(key=lambda x: x.get("score", 0), reverse=True)
        
        return places


# ============================================
# GUÍA PARA EL OTRO DESARROLLADOR
# ============================================
"""
IMPLEMENTACIÓN SUGERIDA:

1. Web Scraping Sources:
   - Timeoutmexico.mx
   - Dónde Ir (dondeir.com)
   - Eventbrite México
   - Ticketmaster México
   - Cartelera CDMX oficial

2. Estructura de Scraping:

class EventScraper:
    def scrape_timeout_mexico(self, date):
        # Scraping de Timeout
        pass
    
    def scrape_eventbrite(self, date):
        # API de Eventbrite
        pass
    
    def scrape_cartelera_cdmx(self, date):
        # Sitio oficial CDMX
        pass
    
    def consolidate_events(self, events_list):
        # Eliminar duplicados
        # Normalizar formato
        pass

3. Almacenamiento:
   - Guardar eventos en BD (tabla events_cache)
   - Cache de 1-6 horas
   - Actualizar automáticamente

4. Integración:
   - Reemplazar get_current_events()
   - Mantener mismo formato de respuesta
   - Agregar más campos si es necesario

5. Testing:
   - Probar con fechas específicas
   - Verificar geocoding de direcciones
   - Validar categorías

CONTACTO:
- Coordinar formato de datos
- Revisar integración juntos
- Compartir schema de BD si es necesario
"""
