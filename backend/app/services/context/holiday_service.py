"""
Servicio de Días Festivos
Detecta días festivos en México y ajusta recomendaciones
"""
from datetime import datetime, date
from typing import Dict, Optional, List
import holidays


class HolidayService:
    def __init__(self):
        # Días festivos de México
        self.mx_holidays = holidays.Mexico(years=[2024, 2025, 2026])
        
        # Eventos especiales de CDMX (hardcoded, pero pueden venir de DB)
        self.special_events = {
            (11, 1): {"name": "Día de Muertos", "impact": "high", "type": "cultural"},
            (11, 2): {"name": "Día de Muertos", "impact": "high", "type": "cultural"},
            (9, 15): {"name": "Grito de Independencia", "impact": "high", "type": "patriotic"},
            (9, 16): {"name": "Día de la Independencia", "impact": "high", "type": "patriotic"},
            (12, 12): {"name": "Día de la Virgen de Guadalupe", "impact": "high", "type": "religious"},
            (12, 24): {"name": "Nochebuena", "impact": "medium", "type": "holiday"},
            (12, 25): {"name": "Navidad", "impact": "high", "type": "holiday"},
            (12, 31): {"name": "Año Nuevo", "impact": "high", "type": "holiday"},
        }
    
    def get_current_context(self, target_date: Optional[date] = None) -> Dict:
        """
        Obtener contexto de día festivo/evento
        
        Returns:
            {
                "is_holiday": True,
                "holiday_name": "Día de Muertos",
                "type": "cultural",
                "impact": "high",
                "crowd_level": "very_high",
                "recommendations": {
                    "book_in_advance": True,
                    "expect_crowds": True,
                    "special_events": True
                }
            }
        """
        if target_date is None:
            target_date = date.today()
        
        # Verificar si es día festivo oficial
        is_official_holiday = target_date in self.mx_holidays
        holiday_name = self.mx_holidays.get(target_date) if is_official_holiday else None
        
        # Verificar eventos especiales
        special_event = self.special_events.get((target_date.month, target_date.day))
        
        # Determinar contexto
        if special_event:
            return self._build_special_context(special_event, target_date)
        elif is_official_holiday:
            return self._build_holiday_context(holiday_name, target_date)
        elif target_date.weekday() >= 5:  # Fin de semana
            return self._build_weekend_context(target_date)
        else:
            return self._build_weekday_context(target_date)
    
    def _build_special_context(self, event: Dict, target_date: date) -> Dict:
        """Contexto para eventos especiales"""
        impact_levels = {
            "high": {"crowd_level": "very_high", "booking_urgency": "critical"},
            "medium": {"crowd_level": "high", "booking_urgency": "recommended"},
            "low": {"crowd_level": "moderate", "booking_urgency": "optional"}
        }
        
        impact = impact_levels.get(event["impact"], impact_levels["medium"])
        
        return {
            "is_holiday": True,
            "is_special_event": True,
            "holiday_name": event["name"],
            "type": event["type"],
            "impact": event["impact"],
            "crowd_level": impact["crowd_level"],
            "date": target_date.isoformat(),
            "recommendations": {
                "book_in_advance": event["impact"] in ["high", "medium"],
                "expect_crowds": True,
                "special_events": True,
                "arrive_early": True,
                "check_schedules": True
            },
            "suggested_categories": self._get_categories_for_event(event["type"])
        }
    
    def _build_holiday_context(self, holiday_name: str, target_date: date) -> Dict:
        """Contexto para días festivos oficiales"""
        return {
            "is_holiday": True,
            "is_special_event": False,
            "holiday_name": holiday_name,
            "type": "official_holiday",
            "impact": "medium",
            "crowd_level": "high",
            "date": target_date.isoformat(),
            "recommendations": {
                "book_in_advance": True,
                "expect_crowds": True,
                "special_events": False,
                "arrive_early": True,
                "check_schedules": True
            }
        }
    
    def _build_weekend_context(self, target_date: date) -> Dict:
        """Contexto para fin de semana"""
        return {
            "is_holiday": False,
            "is_special_event": False,
            "holiday_name": None,
            "type": "weekend",
            "impact": "low",
            "crowd_level": "moderate",
            "date": target_date.isoformat(),
            "recommendations": {
                "book_in_advance": False,
                "expect_crowds": True,
                "special_events": False,
                "arrive_early": False,
                "check_schedules": False
            }
        }
    
    def _build_weekday_context(self, target_date: date) -> Dict:
        """Contexto para día entre semana"""
        return {
            "is_holiday": False,
            "is_special_event": False,
            "holiday_name": None,
            "type": "weekday",
            "impact": "none",
            "crowd_level": "low",
            "date": target_date.isoformat(),
            "recommendations": {
                "book_in_advance": False,
                "expect_crowds": False,
                "special_events": False,
                "arrive_early": False,
                "check_schedules": False
            }
        }
    
    def _get_categories_for_event(self, event_type: str) -> List[str]:
        """Sugerir categorías relevantes para un evento"""
        category_mapping = {
            "cultural": ["museums", "cultural", "art_gallery", "landmark"],
            "patriotic": ["landmark", "museum", "cultural"],
            "religious": ["church", "landmark", "cultural"],
            "holiday": ["restaurants", "entertainment", "nightlife"]
        }
        
        return category_mapping.get(event_type, [])
    
    def adjust_recommendations_by_holiday(
        self, 
        places: list, 
        holiday_context: Dict
    ) -> list:
        """
        Ajustar recomendaciones según contexto de día festivo
        
        Args:
            places: Lista de lugares
            holiday_context: Contexto de día festivo
            
        Returns:
            Lista ajustada
        """
        if not holiday_context.get("is_special_event"):
            return places
        
        suggested_categories = holiday_context.get("suggested_categories", [])
        
        for place in places:
            place_types = place.get("metadata", {}).get("types", [])
            
            # Boost lugares relevantes al evento
            if any(cat in place_types for cat in suggested_categories):
                place["score"] = place.get("score", 0.5) * 1.3  # +30%
                place["holiday_boost"] = True
                place["holiday_reason"] = f"🎉 Perfecto para {holiday_context['holiday_name']}"
            
            # Agregar advertencia de multitudes
            if holiday_context["crowd_level"] in ["high", "very_high"]:
                place["crowd_warning"] = f"👥 Afluencia {holiday_context['crowd_level']} esperada"
        
        # Re-ordenar
        places.sort(key=lambda x: x.get("score", 0), reverse=True)
        
        return places
