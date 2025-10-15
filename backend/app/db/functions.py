# Database functions
import logging
from typing import List
from sqlalchemy import create_engine, Engine
from sqlalchemy.orm import Session
from .models import Base, IncidentLocation, IncidentType, UserLocation

VICINITY_RADIUS_METERS = 500

def get_engine(db_url: str) -> Engine:
    """
    Create and return a SQLAlchemy engine. If the database does not exist, it will be created.
    """
    engine = create_engine(db_url)

    if engine is None:
        raise ValueError("Failed to create database engine")

    Base.metadata.create_all(engine)
    return engine

def create_user_location(engine: Engine, user_id: str, latitude: float, longitude: float) -> UserLocation:
    """
    Create a new user location entry in the database.
    """
    new_location = UserLocation(user_id=user_id, location=f'POINT({longitude} {latitude})')
    with Session(engine) as session:
        session.add(new_location)
        session.commit()
        logging.debug(f"User location created: {new_location}")
    return new_location

def create_incident_type(engine: Engine, type: str, description: str, severity: int, estimated_time: int) -> IncidentType:
    """
    Create a new incident type entry in the database.
    """
    new_type = IncidentType(type=type, description=description, severity=severity, estimated_time=estimated_time)
    with Session(engine) as session:
        session.add(new_type)
        session.commit()
        logging.debug(f"Incident type created: {new_type}")
    return new_type

def get_incident_types(engine: Engine) -> list[IncidentType]:
    """
    Retrieve all incident types from the database.
    """
    with Session(engine) as session:
        types = session.query(IncidentType).all()
    return types

def get_active_incident_vicinity(engine: Engine, latitude: float, longitude: float, radius_meters: float) -> List[IncidentLocation]:
    """
    Retrieve all active incident locations within a certain radius (in meters) of a given latitude and longitude.

    To get an incident location in the vicinity, we use the PostGIS function ST_DWithin to check if the
    location of the incident is within the specified radius.
    """
    with Session(engine) as session:
        incidents = session.query(IncidentLocation).filter(
            IncidentLocation.active == True,
            IncidentLocation.location.ST_DWithin(f'POINT({longitude} {latitude})', radius_meters)
        ).all()
    return incidents

def create_incident_location(engine: Engine, type_id: int, latitude: float, longitude: float) -> IncidentLocation:
    """
    Create a new incident location entry in the database.

    When a new incident location is created, it is marked as active by default and makes all the route journeys
    in the vicinity have a delay according to the estimated time of the incident type.
    """
    new_incident = IncidentLocation(type_id=type_id, location=f'POINT({longitude} {latitude})')
    with Session(engine) as session:
        session.add(new_incident)
        session.commit()
        logging.debug(f"Incident location created: {new_incident}")

    return new_incident

def deactivate_old_incident_locations(engine: Engine) -> None:
    """
    Deactivate all the active incident locations that are older than their estimated time.
    This function should be run periodically to ensure that old incidents are marked as inactive.
    """
    with Session(engine) as session:
        incidents = session.query(IncidentLocation).filter(
            IncidentLocation.active == True,
        ).all()
        for incident in incidents:
            incident.active = False
            logging.debug(f"Deactivating incident location: {incident}")
        session.commit()
