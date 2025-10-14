# Database functions
import logging
from sqlalchemy import create_engine, Engine
from sqlalchemy.orm import Session
from .models import Base, IncidentLocation, IncidentType, UserLocation

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

def create_incident_location(engine: Engine, type_id: int, latitude: float, longitude: float) -> IncidentLocation:
    """
    Create a new incident location entry in the database.
    """
    new_incident = IncidentLocation(type_id=type_id, location=f'POINT({longitude} {latitude})')
    with Session(engine) as session:
        session.add(new_incident)
        session.commit()
        logging.debug(f"Incident location created: {new_incident}")
    return new_incident
