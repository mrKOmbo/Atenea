from sqlalchemy import Column, String, DateTime, JSON, Integer
from datetime import datetime

from app.db.base import Base


class User(Base):
    __tablename__ = "users"
    
    # ID simple y legible
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, unique=True, index=True, nullable=False)  # user_001, user_002, etc.
    
    # Información personal
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)  # Hasheada
    age = Column(Integer, nullable=True)
    nationality = Column(String, nullable=True)  # "Mexico", "Japan", "USA", etc.
    
    # Preferencias y perfil
    preferences = Column(JSON, default=list)  # ["museums", "parks", "restaurants"]
    visited_places = Column(JSON, default=list)  # [{"place_id": "...", "date": "...", "rating": 5}]
    favorite_categories = Column(JSON, default=list)  # Calculado automáticamente
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
