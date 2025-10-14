from sqlalchemy import Column, String, Float, DateTime, Text, Boolean
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry
from datetime import datetime
import uuid

from app.db.base import Base


class Event(Base):
    __tablename__ = "events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_id = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    type = Column(String, nullable=False)  # concert, festival, sports, etc.
    description = Column(Text)
    location = Column(Geometry('POINT', srid=4326))
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    venue_name = Column(String)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime)
    price = Column(Float)
    is_free = Column(Boolean, default=False)
    capacity = Column(Float)
    tickets_available = Column(Float)
    organizer = Column(String)
    website = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
