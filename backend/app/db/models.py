# Database models using SQLAlchemy ORM

from datetime import datetime, time
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
    3. latitude: Latitude of the location (float)
    4. longitude: Longitude of the location (float)
    5. id: Primary key (integer)
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
    5. estimated_time: Estimated time to resolve the incident type in minutes (integer)
    """
    __tablename__ = "incident_types"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    type: Mapped[str] = mapped_column(nullable=False, unique=True)
    description: Mapped[str] = mapped_column(nullable=False)
    severity: Mapped[int] = mapped_column(nullable=False)
    estimated_time: Mapped[int] = mapped_column(nullable=False) # in minutes

class IncidentLocation(Base):
    """
    Table to store incident location data, this will be used to track reported incidents.
    1. id: Primary key (integer)
    2. report_time: Timestamp of the report (datetime)
    3. latitude: Latitude of the incident location (float)
    4. longitude: Longitude of the incident location (float)
    5. active: Status of the incident (boolean)
    6. type_id: Type of incident, foreign key to incident_types (integer)
    """
    __tablename__ = "incident_locations"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    report_time: Mapped[datetime] = mapped_column(nullable=False, default=datetime.now)
    location: Mapped[str] = mapped_column(Geometry('POINT'), nullable=False)
    active: Mapped[bool] = mapped_column(nullable=False, default=True)
    type_id: Mapped[int] = mapped_column(ForeignKey("incident_types.id"), nullable=False)

class TransportAgency(Base):
    """
    Table to store transport agency data, this will be used to manage agencies.
    1. id: Primary key (integer)
    2. name: Name of the transport agency (string)
    """
    __tablename__ = "transport_agencies"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(nullable=False, unique=True)

class RouteName(Base):
    """
    Table to store route names, this will be used to manage routes.
    1. id: Primary key (integer)
    2. name: Name of the route (string)
    3. short_name: Short name of the route (string)
    4. agency_id: Foreign key to transport_agencies (integer)
    """
    __tablename__ = "route_names"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(nullable=False, unique=True)
    short_name: Mapped[str] = mapped_column(nullable=False)
    agency_id: Mapped[int] = mapped_column(ForeignKey("transport_agencies.id"), nullable=False)

class RouteStation(Base):
    """
    Table to store station data, this will be used to manage stations.
    1. id: Primary key (integer)
    2. name: Name of the station (string)
    3. latitude: Latitude of the station (float)
    4. longitude: Longitude of the station (float)
    5. route_id: Foreign key to route_names (integer)
    """
    __tablename__ = "stations"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(nullable=False, unique=True)
    location: Mapped[str] = mapped_column(Geometry('POINT'), nullable=False)
    route_id: Mapped[int] = mapped_column(ForeignKey("route_names.id"), nullable=False)

class RouteJourney(Base):
    """
    Table to store journey data, this will be used to manage journeys.
    1. id: Primary key (integer)
    2. origin_station_id: Foreign key to stations (integer)
    3. destination_station_id: Foreign key to stations (integer)
    4. time_of_journey: Timestamp of the journey (datetime)
    5. delay: Delay in minutes (integer)
    6. route_id: Foreign key to route_names (integer)
    """
    __tablename__ = "journeys"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    origin_station_id: Mapped[int] = mapped_column(ForeignKey("stations.id"), nullable=False)
    destination_station_id: Mapped[int] = mapped_column(ForeignKey("stations.id"), nullable=False)
    time_of_journey: Mapped[time] = mapped_column(nullable=False) # store only time component
    delay: Mapped[int] = mapped_column(nullable=False, default=0) # delay in minutes, nullable
    route_id: Mapped[int] = mapped_column(ForeignKey("route_names.id"), nullable=False)
