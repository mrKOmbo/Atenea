from sqlalchemy import Column, String, Float, DateTime, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from app.db.base import Base


class Recommendation(Base):
    __tablename__ = "recommendations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(String, index=True, nullable=False)
    item_id = Column(String, nullable=False)  # place_id or event_id
    item_type = Column(String, nullable=False)  # place or event
    score = Column(Float)  # AI confidence score
    distance = Column(Float)  # km from user location
    time_estimate = Column(Float)  # minutes in public transport
    reason = Column(String)  # Why recommended
    extra_data = Column(JSON)  # Additional info
    created_at = Column(DateTime, default=datetime.utcnow)
