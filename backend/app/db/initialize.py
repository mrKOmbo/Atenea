# Initialize the database with sample data
import logging
from sqlalchemy import Engine
from sqlalchemy.orm import Session
from .models import IncidentType

def initialize_database_data(engine: Engine) -> None:
    """
    Initialize the database with default data if necessary.
    """
    with Session(engine) as session:
        if session.query(IncidentType).count() == 0:
            logging.info("Database is empty. Generating default data.")
            generate_default_incident_types(engine)
        else:
            logging.debug("Database already initialized with data.")

def generate_default_incident_types(engine: Engine) -> None:
    """
    Generate default incident types in the database if they do not exist.
    """
    default_types = [
        {"type": "Delay", "description": "Service is delayed", "severity": 2, "estimated_time": 20},
        {"type": "Maintenance", "description": "Scheduled maintenance", "severity": 3, "estimated_time": 30},
        {"type": "Weather", "description": "Weather-related disruption", "severity": 3, "estimated_time": 30},
        {"type": "Accident", "description": "Accident on route", "severity": 4, "estimated_time": 40},
        {"type": "Temporal Closure", "description": "Route is temporarily closed", "severity": 6, "estimated_time": 60},
    ]

    with Session(engine) as session:
        existing_types = {it.type for it in session.query(IncidentType).all()}
        for it in default_types:
            if it["type"] not in existing_types:
                new_type = IncidentType(
                    type=it["type"],
                    description=it["description"],
                    severity=it["severity"],
                    estimated_time=it["estimated_time"]
                )
                session.add(new_type)
        session.commit()
