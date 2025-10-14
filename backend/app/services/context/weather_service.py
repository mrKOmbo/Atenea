"""
Servicio de Clima
Obtiene información del clima actual usando OpenWeatherMap API
"""
import requests
from typing import Dict, Optional
from datetime import datetime
import os


class WeatherService:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("OPENWEATHER_API_KEY")
        self.base_url = "https://api.openweathermap.org/data/2.5/weather"
    
    def get_current_weather(self, lat: float, lon: float) -> Dict:
        """
        Obtener clima actual para una ubicación
        
        Returns:
            {
                "condition": "rainy" | "sunny" | "cloudy" | "clear",
                "temperature": 22,
                "feels_like": 20,
                "humidity": 65,
                "description": "lluvia ligera",
                "is_raining": True,
                "is_extreme": False,
                "recommendations": {
                    "indoor_preferred": True,
                    "bring_umbrella": True,
                    "avoid_outdoor": False
                }
            }
        """
        if not self.api_key:
            print("⚠️ OpenWeather API key no configurada, usando clima por defecto")
            return self._get_default_weather()
        
        try:
            params = {
                "lat": lat,
                "lon": lon,
                "appid": self.api_key,
                "units": "metric",
                "lang": "es"
            }
            
            response = requests.get(self.base_url, params=params, timeout=5)
            response.raise_for_status()
            data = response.json()
            
            return self._parse_weather(data)
            
        except Exception as e:
            print(f"⚠️ Error obteniendo clima: {e}")
            return self._get_default_weather()
    
    def _parse_weather(self, data: Dict) -> Dict:
        """Parsear respuesta de OpenWeather"""
        weather = data["weather"][0]
        main = data["main"]
        
        # Condición principal
        condition_code = weather["id"]
        condition = self._get_condition_category(condition_code)
        
        # Detectar lluvia
        is_raining = condition_code >= 200 and condition_code < 600
        
        # Detectar clima extremo
        is_extreme = (
            condition_code < 300 or  # Tormenta
            condition_code >= 600 and condition_code < 700 or  # Nieve
            main["temp"] > 35 or  # Calor extremo
            main["temp"] < 5  # Frío extremo
        )
        
        # Recomendaciones basadas en clima
        recommendations = {
            "indoor_preferred": is_raining or is_extreme,
            "bring_umbrella": is_raining,
            "avoid_outdoor": is_extreme,
            "prefer_shade": main["temp"] > 30,
            "bring_jacket": main["temp"] < 15
        }
        
        return {
            "condition": condition,
            "temperature": round(main["temp"]),
            "feels_like": round(main["feels_like"]),
            "humidity": main["humidity"],
            "description": weather["description"],
            "icon": weather["icon"],
            "is_raining": is_raining,
            "is_extreme": is_extreme,
            "recommendations": recommendations,
            "timestamp": datetime.now().isoformat()
        }
    
    def _get_condition_category(self, code: int) -> str:
        """Categorizar condición del clima"""
        if code >= 200 and code < 300:
            return "thunderstorm"
        elif code >= 300 and code < 400:
            return "drizzle"
        elif code >= 500 and code < 600:
            return "rainy"
        elif code >= 600 and code < 700:
            return "snowy"
        elif code >= 700 and code < 800:
            return "foggy"
        elif code == 800:
            return "clear"
        elif code > 800:
            return "cloudy"
        return "unknown"
    
    def _get_default_weather(self) -> Dict:
        """Clima por defecto cuando no hay API key"""
        return {
            "condition": "clear",
            "temperature": 22,
            "feels_like": 22,
            "humidity": 50,
            "description": "despejado",
            "icon": "01d",
            "is_raining": False,
            "is_extreme": False,
            "recommendations": {
                "indoor_preferred": False,
                "bring_umbrella": False,
                "avoid_outdoor": False,
                "prefer_shade": False,
                "bring_jacket": False
            },
            "timestamp": datetime.now().isoformat(),
            "default": True
        }
    
    def adjust_recommendations_by_weather(
        self, 
        places: list, 
        weather: Dict
    ) -> list:
        """
        Ajustar prioridad de lugares según clima
        
        Args:
            places: Lista de lugares recomendados
            weather: Información del clima
            
        Returns:
            Lista de lugares con score ajustado
        """
        recommendations = weather.get("recommendations", {})
        
        for place in places:
            place_types = place.get("metadata", {}).get("types", [])
            
            # Si está lloviendo, priorizar lugares cubiertos
            if recommendations.get("indoor_preferred"):
                if self._is_indoor(place_types):
                    place["score"] = place.get("score", 0.5) * 1.2  # +20% score
                    place["weather_boost"] = True
                    place["weather_reason"] = "🌧️ Lugar cubierto ideal para clima lluvioso"
                else:
                    place["score"] = place.get("score", 0.5) * 0.8  # -20% score
                    place["weather_warning"] = "⚠️ Lugar al aire libre, considera clima"
            
            # Si hace mucho calor, priorizar lugares con sombra o clima
            elif recommendations.get("prefer_shade"):
                if self._is_indoor(place_types) or "park" in place_types:
                    place["score"] = place.get("score", 0.5) * 1.1
                    place["weather_reason"] = "☀️ Lugar fresco o con sombra"
        
        # Re-ordenar por nuevo score
        places.sort(key=lambda x: x.get("score", 0), reverse=True)
        
        return places
    
    def _is_indoor(self, place_types: list) -> bool:
        """Determinar si un lugar es mayormente interior"""
        indoor_types = {
            "museum", "art_gallery", "library", "shopping_mall",
            "restaurant", "cafe", "bar", "movie_theater",
            "aquarium", "bowling_alley", "casino", "gym",
            "spa", "store", "supermarket"
        }
        
        return any(t in indoor_types for t in place_types)
