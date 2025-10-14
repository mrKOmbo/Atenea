from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime


class UserRegister(BaseModel):
    """Schema para registro de usuario"""
    name: str
    email: EmailStr
    password: str
    age: Optional[int] = None
    nationality: Optional[str] = None
    preferences: Optional[List[str]] = []


class UserLogin(BaseModel):
    """Schema para login"""
    email: EmailStr
    password: str


class UserProfile(BaseModel):
    """Schema de perfil de usuario (respuesta)"""
    user_id: str
    name: str
    email: str
    age: Optional[int] = None
    nationality: Optional[str] = None
    preferences: List[str]
    visited_places: List[dict]
    favorite_categories: List[str]
    created_at: str
    last_login: Optional[str] = None


class UserUpdate(BaseModel):
    """Schema para actualizar perfil"""
    name: Optional[str] = None
    age: Optional[int] = None
    nationality: Optional[str] = None
    preferences: Optional[List[str]] = None


class VisitedPlace(BaseModel):
    """Schema para registrar lugar visitado"""
    place_id: str
    place_name: str
    rating: Optional[int] = None  # 1-5
    category: Optional[str] = None


class LoginResponse(BaseModel):
    """Response de login exitoso"""
    user_id: str
    name: str
    email: str
    nationality: Optional[str] = None
    message: str
