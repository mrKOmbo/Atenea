# Initialize the database with sample data
import csv
from datetime import datetime
from sqlalchemy import Engine
from sqlalchemy.orm import Session
from .models import TransportAgency, RouteName, RouteStation, RouteJourney

def import_from_csv(engine: Engine, file_path: str) -> None:
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
                    origin_lon = float(row['origin_lon'])
                    origin_lat = float(row['origin_lat'])
                    origin_station = RouteStation(
                        name=row['origin_stop'],
                        location=f'POINT({origin_lon} {origin_lat})',
                        route_id=route_name.id
                    )
                    session.add(origin_station)
                    session.flush()

                # Get or create destination RouteStation
                destiny_station = session.query(RouteStation).filter_by(name=row['destiny_stop']).first()
                if not destiny_station:
                    destiny_lon = float(row['destiny_lon'])
                    destiny_lat = float(row['destiny_lat'])
                    destiny_station = RouteStation(
                        name=row['destiny_stop'],
                        location=f'POINT({destiny_lon} {destiny_lat})',
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

