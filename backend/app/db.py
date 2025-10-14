# Database connection and query execution
# We are using SQLAlchemy for database interactions
import csv
from datetime import datetime, time
from sqlalchemy import create_engine, ForeignKey, Engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session

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
    latitude: Mapped[float] = mapped_column(nullable=False)
    longitude: Mapped[float] = mapped_column(nullable=False)

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
    latitude: Mapped[float] = mapped_column(nullable=False)
    longitude: Mapped[float] = mapped_column(nullable=False)
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
    latitude: Mapped[float] = mapped_column(nullable=False)
    longitude: Mapped[float] = mapped_column(nullable=False)
    route_id: Mapped[int] = mapped_column(ForeignKey("route_names.id"), nullable=False)

class RouteJourney(Base):
    """
    Table to store journey data, this will be used to manage journeys.
    1. id: Primary key (integer)
    2. origin_station_id: Foreign key to stations (integer)
    3. destination_station_id: Foreign key to stations (integer)
    4. time_of_journey: Timestamp of the journey (datetime)
    5. route_id: Foreign key to route_names (integer)
    """
    __tablename__ = "journeys"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    origin_station_id: Mapped[int] = mapped_column(ForeignKey("stations.id"), nullable=False)
    destination_station_id: Mapped[int] = mapped_column(ForeignKey("stations.id"), nullable=False)
    time_of_journey: Mapped[time] = mapped_column(nullable=False)
    route_id: Mapped[int] = mapped_column(ForeignKey("route_names.id"), nullable=False)

def get_engine(db_url: str) -> Engine:
    """
    Create and return a SQLAlchemy engine. If the database does not exist, it will be created.
    """
    engine = create_engine(db_url)

    if engine is None:
        raise ValueError("Failed to create database engine")

    # Create all tables if they do not exist
    Base.metadata.create_all(engine)
    return engine

def create_user_location(engine: Engine, user_id: str, latitude: float, longitude: float):
    """
    Create a new user location entry in the database.
    """
    new_location = UserLocation(user_id=user_id, latitude=latitude, longitude=longitude)
    with Session(engine) as session:
        session.add(new_location)
        session.commit()
    return new_location

def import_from_csv(engine: Engine, file_path: str):
    """
    Import route and journey data from a CSV file.
    The CSV file should have the following columns:
    agency_name,route_long_name,route_short_name,origin_stop,origin_lat,origin_lon,destiny_stop,destiny_lat,destiny_lon,time_of_journey
    """

    with open(file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        with Session(engine) as session:
            for row in reader:
                # Get or create TransportAgency
                agency = session.query(TransportAgency).filter_by(name=row['agency_name']).first()
                if not agency:
                    agency = TransportAgency(name=row['agency_name'])
                    session.add(agency)
                    session.flush() # Use flush to get the ID before commit

                # Get or create RouteName
                route_name = session.query(RouteName).filter_by(name=row['route_long_name']).first()
                if not route_name:
                    route_name = RouteName(
                        name=row['route_long_name'],
                        short_name=row['route_short_name'],
                        agency_id=agency.id
                    )
                    session.add(route_name)
                    session.flush()

                # Get or create origin RouteStation
                origin_station = session.query(RouteStation).filter_by(name=row['origin_stop']).first()
                if not origin_station:
                    origin_station = RouteStation(
                        name=row['origin_stop'],
                        latitude=float(row['origin_lat']),
                        longitude=float(row['origin_lon']),
                        route_id=route_name.id
                    )
                    session.add(origin_station)
                    session.flush()

                # Get or create destination RouteStation
                destiny_station = session.query(RouteStation).filter_by(name=row['destiny_stop']).first()
                if not destiny_station:
                    destiny_station = RouteStation(
                        name=row['destiny_stop'],
                        latitude=float(row['destiny_lat']),
                        longitude=float(row['destiny_lon']),
                        route_id=route_name.id
                    )
                    session.add(destiny_station)
                    session.flush()

                # Create RouteJourney — store only the time component
                journey_time = datetime.strptime(row['time_of_journey'], '%H:%M:%S').time()

                journey = RouteJourney(
                    origin_station_id=origin_station.id,
                    destination_station_id=destiny_station.id,
                    time_of_journey=journey_time,
                    route_id=route_name.id
                )
                session.add(journey)
            
            session.commit()

