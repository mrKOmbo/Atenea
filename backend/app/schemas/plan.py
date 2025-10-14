from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime


class ActivityInput(BaseModel):
    type: str  # "museum", "park", "event"
    id: str  # place_id or event_id


class PlanCreateRequest(BaseModel):
    user_id: str
    activities: List[ActivityInput]
    start_time: datetime
    name: Optional[str] = None


class TransportOption(BaseModel):
    duration_minutes: int
    duration_text: str
    distance_km: float
    distance_text: str


class TransportDetails(BaseModel):
    suggested_mode: str
    duration_minutes: int
    distance_km: float
    all_options: Dict[str, TransportOption]
    route: List[Dict[str, float]]


class PlanActivityResponse(BaseModel):
    sequence: int
    activity_name: str
    activity_type: str
    start_time: str
    end_time: str
    duration_minutes: int
    location: Dict[str, float]
    transport_to_here: Optional[TransportDetails] = None


class PlanSummary(BaseModel):
    total_activities: int
    total_time_minutes: int
    total_time_formatted: str
    total_activity_time_minutes: int
    total_travel_time_minutes: int
    activity_time_formatted: str
    travel_time_formatted: str


class PlanResponse(BaseModel):
    plan_id: str
    name: Optional[str] = None
    user_id: str
    start_time: str
    end_time: str
    activities: List[PlanActivityResponse]
    summary: PlanSummary
    status: str
    created_at: str


class PlanUpdateRequest(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None


class PlanCompleteRequest(BaseModel):
    """Schema para completar un plan con ratings opcionales"""
    activity_ratings: Optional[Dict[str, int]] = None  # {place_id: rating (1-5)}
