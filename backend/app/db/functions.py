# Database functions
from sqlalchemy import create_engine, Engine
from sqlalchemy.orm import Session

from .models import Base, UserLocation

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
    return new_location
