"""
Servicio Principal de Contexto Inteligente
Integra todas las fuentes de contexto para recomendaciones inteligentes
"""
from typing import Dict, List, Optional
from datetime import date

from .weather_service import WeatherService
from .holiday_service import HolidayService
from .events_service import EventsService


class ContextAwareService:
    """
    Servicio que integra múltiples fuentes de contexto:
    - Clima actual
    - Días festivos
    - Eventos en la ciudad
    - Tráfico (via eventos)
    """
    
    def __init__(self):
        self.weather_service = WeatherService()
        self.holiday_service = HolidayService()
        self.events_service = EventsService()
    
    def get_full_context(
        self, 
        lat: float, 
        lon: float,
        target_date: Optional[date] = None
    ) -> Dict:
        """
        Obtener contexto completo para recomendaciones
        
        Args:
            lat: Latitud del usuario
            lon: Longitud del usuario
            target_date: Fecha objetivo (default: hoy)
            
        Returns:
            {
                "weather": {...},
                "holiday": {...},
                "events": [...],
                "summary": {
                    "has_alerts": True,
                    "main_factors": ["rain", "high_crowd", "traffic"],
                    "recommendation_adjustments": {
                        "prefer_indoor": True,
                        "expect_crowds": True,
                        "book_advance": True
                    }
                }
            }
        """
        # Obtener cada contexto
        weather = self.weather_service.get_current_weather(lat, lon)
        holiday = self.holiday_service.get_current_context(target_date)
        events = self.events_service.get_current_events(lat, lon, target_date=target_date)
        
        # Generar resumen inteligente
        summary = self._generate_context_summary(weather, holiday, events)
        
        return {
            "weather": weather,
            "holiday": holiday,
            "events": events,
            "summary": summary,
            "location": {"lat": lat, "lon": lon},
            "timestamp": weather.get("timestamp")
        }
    
    def _generate_context_summary(
        self, 
        weather: Dict, 
        holiday: Dict, 
        events: List[Dict]
    ) -> Dict:
        """
        Generar resumen inteligente del contexto
        """
        factors = []
        alerts = []
        adjustments = {
            "prefer_indoor": False,
            "expect_crowds": False,
            "book_advance": False,
            "avoid_outdoor": False,
            "check_traffic": False
        }
        
        # Analizar clima
        if weather.get("is_raining"):
            factors.append("rain")
            alerts.append("🌧️ Está lloviendo")
            adjustments["prefer_indoor"] = True
        
        if weather.get("is_extreme"):
            factors.append("extreme_weather")
            alerts.append(f"⚠️ Clima extremo: {weather.get('description')}")
            adjustments["avoid_outdoor"] = True
        
        # Analizar día festivo
        if holiday.get("is_holiday") or holiday.get("is_special_event"):
            factors.append("holiday")
            alerts.append(f"🎉 {holiday.get('holiday_name')}")
            adjustments["expect_crowds"] = True
            
            if holiday.get("impact") in ["high", "medium"]:
                adjustments["book_advance"] = True
        
        # Analizar eventos
        high_impact_events = [e for e in events if e.get("impact") == "high"]
        traffic_events = [e for e in events if e.get("affects_traffic")]
        
        if high_impact_events:
            factors.append("major_events")
            event_names = [e["name"] for e in high_impact_events[:2]]
            alerts.append(f"🎪 Eventos: {', '.join(event_names)}")
            adjustments["expect_crowds"] = True
        
        if traffic_events:
            factors.append("traffic")
            alerts.append(f"🚗 {len(traffic_events)} evento(s) afectando tráfico")
            adjustments["check_traffic"] = True
        
        return {
            "has_alerts": len(alerts) > 0,
            "main_factors": factors,
            "alerts": alerts,
            "recommendation_adjustments": adjustments,
            "impact_level": self._calculate_overall_impact(factors)
        }
    
    def _calculate_overall_impact(self, factors: List[str]) -> str:
        """
        Calcular nivel de impacto general
        """
        impact_weights = {
            "extreme_weather": 3,
            "rain": 1,
            "holiday": 2,
            "major_events": 2,
            "traffic": 1
        }
        
        total_impact = sum(impact_weights.get(f, 0) for f in factors)
        
        if total_impact >= 5:
            return "high"
        elif total_impact >= 3:
            return "medium"
        elif total_impact >= 1:
            return "low"
        else:
            return "none"
    
    def apply_context_to_recommendations(
        self, 
        places: list, 
        context: Dict
    ) -> list:
        """
        Aplicar todo el contexto a recomendaciones
        
        Args:
            places: Lista de lugares recomendados
            context: Contexto completo (de get_full_context)
            
        Returns:
            Lista de lugares ajustados con contexto
        """
        # Aplicar cada tipo de ajuste
        places = self.weather_service.adjust_recommendations_by_weather(
            places, 
            context["weather"]
        )
        
        places = self.holiday_service.adjust_recommendations_by_holiday(
            places, 
            context["holiday"]
        )
        
        places = self.events_service.adjust_recommendations_by_events(
            places, 
            context["events"],
            context["location"]["lat"],
            context["location"]["lon"]
        )
        
        # Agregar contexto general a cada lugar
        for place in places:
            place["context"] = {
                "weather": {
                    "condition": context["weather"]["condition"],
                    "temperature": context["weather"]["temperature"],
                    "is_raining": context["weather"]["is_raining"]
                },
                "alerts": context["summary"]["alerts"],
                "impact_level": context["summary"]["impact_level"]
            }
        
        return places
    
    def get_context_narrative(self, context: Dict) -> str:
        """
        Generar narrativa en lenguaje natural del contexto
        
        Returns:
            "Hoy es un día soleado perfecto para explorar. 
             Ten en cuenta que es Día de Muertos, así que habrá 
             mucha gente en el Centro Histórico..."
        """
        parts = []
        
        weather = context["weather"]
        holiday = context["holiday"]
        events = context["events"]
        summary = context["summary"]
        
        # Descripción del clima
        if weather["is_raining"]:
            parts.append(f"Está lloviendo ({weather['description']}), por lo que recomendamos lugares cubiertos.")
        elif weather["is_extreme"]:
            parts.append(f"El clima es extremo ({weather['description']}), mejor evita actividades al aire libre.")
        else:
            parts.append(f"El clima está {weather['description']} con {weather['temperature']}°C.")
        
        # Información de día festivo
        if holiday.get("is_holiday") or holiday.get("is_special_event"):
            parts.append(f"Hoy es {holiday['holiday_name']}, espera más visitantes de lo normal.")
        
        # Eventos importantes
        high_impact = [e for e in events if e.get("impact") == "high"]
        if high_impact:
            event_list = ", ".join([e["name"] for e in high_impact[:2]])
            parts.append(f"Hay eventos importantes: {event_list}.")
        
        # Recomendaciones finales
        if summary.get("has_alerts"):
            if summary["recommendation_adjustments"]["book_advance"]:
                parts.append("Te recomendamos reservar con anticipación.")
            if summary["recommendation_adjustments"]["check_traffic"]:
                parts.append("Considera el tráfico adicional por los eventos.")
        
        return " ".join(parts)
