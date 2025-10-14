# Route finding algorithms
import heapq
from datetime import timedelta
from typing import List, Tuple
from geoalchemy2 import Geometry
from sqlalchemy import func, Engine
from sqlalchemy.orm import Session
from .models import RouteJourney, RouteStation

def route_finding_algorithm(engine: Engine, starting_coordinates: Geometry, ending_coordinates: Geometry) -> Tuple[List[RouteStation], float]:
    """
    Find the optimal route between two locations using dijkstra's algorithm.
    1. It finds the nearest stations to the starting and ending coordinates.
    2. It then finds the shortest path between these two stations using the estimated travel times and delays.
    3. Finally, it returns the list of stations that make up the optimal route.
    """
    with Session(engine) as session:
        # 1. Find the nearest stations to the starting and ending coordinates
        start_station = session.query(RouteStation).order_by(func.ST_Distance(RouteStation.location, starting_coordinates)).first()
        end_station = session.query(RouteStation).order_by(func.ST_Distance(RouteStation.location, ending_coordinates)).first()

        if not start_station or not end_station:
            return ([], 0.0)  # No stations found

        # 2. Dijkstra's algorithm
        # Priority queue: (total_time, station_id, path)
        pq = [(timedelta(0), start_station.id, [start_station])]
        visited = set()

        while pq:
            total_time, current_station_id, path = heapq.heappop(pq)

            if current_station_id in visited:
                continue
            
            visited.add(current_station_id)

            if current_station_id == end_station.id:
                return path, total_time.total_seconds() / 60  # Return path and total time in minutes

            # Get all journeys from the current station
            journeys = session.query(RouteJourney).filter(RouteJourney.origin_station_id == current_station_id).all()

            for journey in journeys:
                if journey.destination_station_id not in visited:
                    journey_time = timedelta(
                        hours=journey.time_of_journey.hour,
                        minutes=journey.time_of_journey.minute,
                        seconds=journey.time_of_journey.second
                    )
                    total_delay = timedelta(minutes=journey.delay)
                    
                    new_total_time = total_time + journey_time + total_delay
                    
                    destination_station = session.get(RouteStation, journey.destination_station_id)
                    if destination_station:
                        new_path = path + [destination_station]
                        heapq.heappush(pq, (new_total_time, journey.destination_station_id, new_path))

        return ([], 0.0)
