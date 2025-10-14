# Database functions
import datetime
import logging
from typing import List
from sqlalchemy import create_engine, Engine, func
from sqlalchemy.orm import Session
from .models import Base, IncidentLocation, IncidentType, RouteStation, UserLocation, RouteJourney
from .algorithms import route_finding_algorithm
from geoalchemy2 import Geometry

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

def get_route_journeys_in_vicinity(engine: Engine, latitude: float, longitude: float, radius_meters: float) -> List[RouteJourney]:
    """
    Retrieve all route journeys within a certain radius (in meters) of a given latitude and longitude.

    To get a route journey in the vicinity, we use the PostGIS function ST_DWithin to check if the
    location of the origin or destination of the route journey is within the specified radius.
    """
    with Session(engine) as session:
        stations = session.query(RouteStation).filter(
            RouteStation.location.ST_DWithin(f'POINT({longitude} {latitude})', radius_meters)
        ).all()

        station_ids = [station.id for station in stations]

        journeys = session.query(RouteJourney).filter(
            (RouteJourney.origin_station_id.in_(station_ids)) |
            (RouteJourney.destination_station_id.in_(station_ids))
        ).all()
    return journeys

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

    # Get all route journeys in the vicinity (e.g., within 500 meters)
    nearby_journeys = get_route_journeys_in_vicinity(engine, latitude, longitude, radius_meters=VICINITY_RADIUS_METERS)

    # Get the incident type to know the estimated time
    with Session(engine) as session:
        incident_type = session.get(IncidentType, type_id)
        if incident_type is None:
            # This should not happen as type_id is a foreign key, but just in case
            logging.error(f"Incident type with ID {type_id} not found")
            return new_incident

    # Add delay to each nearby journey based on the incident type's estimated time
    for journey in nearby_journeys:
        journey.delay = (journey.delay or 0) + incident_type.estimated_time
        logging.info(f"Added delay to journey ID {journey.id}: {journey.delay} seconds")
        with Session(engine) as session:
            session.merge(journey)
            session.commit()

    return new_incident

def deactivate_old_incident_locations(engine: Engine) -> None:
    """
    Deactivate all the active incident locations that are older than their estimated time and remove delays from route journeys.
    This function should be run periodically to ensure that old incidents are marked as inactive.
    """
    with Session(engine) as session:
        incidents = session.query(IncidentLocation).filter(
            IncidentLocation.active == True,
        ).all()
        for incident in incidents:
            # Get the incident type to know the estimated time
            incident_type = session.get(IncidentType, incident.type_id)
            if incident_type is None:
                logging.error(f"Incident type with ID {incident.type_id} not found")
                continue
            elapsed_time = (datetime.datetime.now() - incident.report_time).total_seconds() # in seconds
            if elapsed_time >= incident_type.estimated_time:
                incident.active = False
                logging.info(f"Deactivating incident ID {incident.id} after {elapsed_time} seconds")
                session.merge(incident)

                # Get all route journeys in the vicinity (e.g., within 500 meters)
                incident_location = incident.location
                longitude, latitude = map(float, incident_location.lstrip('POINT(').rstrip(')').split())
                nearby_journeys = get_route_journeys_in_vicinity(engine, latitude, longitude, radius_meters=VICINITY_RADIUS_METERS)

                # Remove delay from each nearby journey based on the incident type's estimated time
                for journey in nearby_journeys:
                    journey.delay = max(0, journey.delay - incident_type.estimated_time)
                    logging.info(f"Removed delay from journey ID {journey.id}: {journey.delay} seconds")
                    session.merge(journey)

        session.commit()

def get_route_information(engine: Engine, origin_latitude: float, origin_longitude: float, destination_latitude: float, destination_longitude: float) -> dict:
    """
    Retrieve the route information between two coordinates using the route finding algorithm.

    Add alerts of the delays that may exist in the route due to active incidents.
    """

    origin_coordinates = f'POINT({origin_longitude} {origin_latitude})'
    destination_coordinates = f'POINT({destination_longitude} {destination_latitude})'

    estimated_total_time, route = route_finding_algorithm(engine, origin_coordinates, destination_coordinates)

    if not route:
        return {"route": [], "estimated_total_time": 0.0, "incidents": []}

    # Search for incidents near each station in the route
    with Session(engine) as session:
        stations = []
        for step in route:
            station_latitude = step['from']['latitude']
            station_longitude = step['from']['longitude']
            stations.append((station_latitude, station_longitude))

        incidents = []
        # For each station, find nearby active incidents
        for station in stations:
            station_latitude, station_longitude = station
            nearby_incidents = get_active_incident_vicinity(engine, station_latitude, station_longitude, radius_meters=VICINITY_RADIUS_METERS)
            for incident in nearby_incidents:
                incident_type = session.get(IncidentType, incident.type_id)
                if incident_type:
                    incident_coords = session.query(
                        func.ST_Y(incident.location).label('latitude'),
                        func.ST_X(incident.location).label('longitude')
                    ).one()
                    incidents.append({
                        "type": incident_type.type,
                        "description": incident_type.description,
                        "severity": incident_type.severity,
                        "estimated_time": incident_type.estimated_time,
                        "location": {
                            "latitude": incident_coords.latitude,
                            "longitude": incident_coords.longitude
                        },
                        "report_time": incident.report_time.isoformat()
                    })


    return {"route": route, "estimated_total_time": estimated_total_time, "incidents": incidents}
