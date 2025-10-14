from typing import List, Union
from pydantic_settings import BaseSettings
from pydantic import field_validator
import os

class Settings(BaseSettings):
    # API Settings
    PROJECT_NAME: str = "Atenea Backend"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # CORS
    BACKEND_CORS_ORIGINS: Union[List[str], str] = ["http://localhost:3000", "http://localhost:8080"]
    
    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/atenea"
    
    # AI Configuration
    AI_PROVIDER: str = "gemini"  # opciones: openai, gemini, ollama
    
    # Google Gemini
    GOOGLE_GEMINI_API_KEY: str = os.getenv("GOOGLE_GEMINI_API_KEY")
    
    # Google Maps
    GOOGLE_MAPS_API_KEY: str = os.getenv("GOOGLE_MAPS_API_KEY")
    
    # OpenWeather API
    OPENWEATHER_API_KEY: str = os.getenv("OPENWEATHER_API_KEY")

    # JWT Secret
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            # Si es string vacío, retornar lista por defecto
            if not v or v.strip() == "":
                return ["http://localhost:3000", "http://localhost:8080"]
            # Si es string separado por comas
            if "," in v:
                return [i.strip() for i in v.split(",")]
            # Si es un solo valor
            return [v]
        elif isinstance(v, list):
            return v
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
