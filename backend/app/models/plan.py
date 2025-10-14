from sqlalchemy import Column, String, Float, DateTime, ForeignKey, JSON, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.db.base import Base


class Plan(Base):
    __tablename__ = "plans"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    plan_id = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(String, index=True, nullable=False)
    name = Column(String)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime)
    total_estimated_time = Column(Float)  # minutes
    status = Column(String, default="draft")  # draft, active, completed, cancelled
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    activities = relationship("PlanActivity", back_populates="plan", cascade="all, delete-orphan")


class PlanActivity(Base):
    __tablename__ = "plan_activities"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    plan_id = Column(UUID(as_uuid=True), ForeignKey("plans.id"), nullable=False)
    activity_id = Column(String, nullable=False)  # place_id or event_id
    activity_type = Column(String, nullable=False)  # place or event
    activity_name = Column(String)
    activity_category = Column(String, nullable=True)  # restaurants, museums, cafes, etc.
    sequence = Column(Integer, nullable=False)  # Order in the plan
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    transport = Column(JSON)  # Transport details to reach this activity
    extra_data = Column(JSON)  # Extra data: rating, description, etc.
    created_at = Column(DateTime, default=datetime.utcnow)
    
    plan = relationship("Plan", back_populates="activities")
