# Database models using SQLAlchemy ORM

from datetime import datetime
from sqlalchemy import ForeignKey
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from geoalchemy2 import Geometry

class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass

class UserLocation(Base):
    """
    Table to store user location data, this will be used to track user movements.
    1. user_id: ID of the user (string)
    2. time_date: Timestamp of the location data (datetime)
    3. location: Geographical location of the user (POINT)
    4. id: Primary key (integer)
    """
    __tablename__ = "user_locations"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[str] = mapped_column(nullable=False)
    time_date: Mapped[datetime] = mapped_column(nullable=False, default=datetime.now)
    location: Mapped[str] = mapped_column(Geometry('POINT'), nullable=False)

class IncidentType(Base):
    """
    Table to store incident types, this will be used to categorize incidents.
    1. id: Primary key (integer)
    2. type: Type of incident (string)
    3. description: Description of the incident type (string)
    4. severity: Severity level of the incident type (integer)
    5. estimated_time: Estimated time to resolve the incident type in seconds (integer)
    """
    __tablename__ = "incident_types"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    type: Mapped[str] = mapped_column(nullable=False, unique=True)
    description: Mapped[str] = mapped_column(nullable=False)
    severity: Mapped[int] = mapped_column(nullable=False)
    estimated_time: Mapped[int] = mapped_column(nullable=False) # in seconds

class IncidentLocation(Base):
    """
    Table to store incident location data, this will be used to track reported incidents.
    1. id: Primary key (integer)
    2. report_time: Timestamp of the report (datetime)
    3. location: Geographical location of the incident (POINT)
    4. active: Status of the incident (boolean)
    5. type_id: Type of incident, foreign key to incident_types (integer)
    """
    __tablename__ = "incident_locations"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    report_time: Mapped[datetime] = mapped_column(nullable=False, default=datetime.now)
    location: Mapped[str] = mapped_column(Geometry('POINT'), nullable=False)
    active: Mapped[bool] = mapped_column(nullable=False, default=True)
    type_id: Mapped[int] = mapped_column(ForeignKey("incident_types.id"), nullable=False)
