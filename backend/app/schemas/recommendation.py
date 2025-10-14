from pydantic import BaseModel
from typing import List, Optional, Any, Dict
from datetime import datetime


class RecommendationRequest(BaseModel):
    user_id: str
    location: dict  # {"lat": float, "lon": float}
    preferences: List[str]  # ["museums", "parks", "events"]


class RecommendationItem(BaseModel):
    name: str
    type: str
    location: dict
    description: Optional[str] = None
    rating: Optional[float] = None
    distance: float  # km
    time_estimate: int  # minutes
    score: Optional[float] = None
    reason: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class RecommendationResponse(BaseModel):
    recommendations: List[RecommendationItem]
    context: Optional[Dict[str, Any]] = None  # Contexto inteligente
    context_narrative: Optional[str] = None  # Narrativa del contexto
