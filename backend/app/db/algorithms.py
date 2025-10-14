# Route finding algorithms
import heapq
import logging
from typing import List, Tuple, Optional
from sqlalchemy import Engine, func
from sqlalchemy.orm import Session, joinedload
from .models import RouteJourney, RouteStation, RouteName, TransportAgency

def route_finding_algorithm(engine: Engine, origin_coordinates: str, destination_coordinates: str) -> Tuple[Optional[float], Optional[List[dict]]]:
    """
    Find the optimal route between two geographical coordinates using a Dijkstra's algorithm on a database graph.
    It searches for the nearest stations to the origin and destination coordinates and then finds the best route between them.
    """
    start_name = None
    end_name = None

    with Session(engine) as session:
        origin_station = session.query(RouteStation).order_by(
            func.ST_Distance(func.ST_SetSRID(RouteStation.location, 4326), func.ST_GeomFromText(origin_coordinates, 4326))
        ).first()

        destination_station = session.query(RouteStation).order_by(
            func.ST_Distance(func.ST_SetSRID(RouteStation.location, 4326), func.ST_GeomFromText(destination_coordinates, 4326))
        ).first()

        if origin_station:
            start_name = origin_station.name
        if destination_station:
            end_name = destination_station.name

    if start_name is None or end_name is None:
        logging.error("Could not find nearest stations for the given coordinates.")
        return None, None
    
    return find_route(engine, start_name, end_name)

def find_route(engine: Engine, start_name: str, end_name: str, start_agency: Optional[str] = None, end_agency: Optional[str] = None) -> Tuple[Optional[float], Optional[List[dict]]]:
    """
    Find the optimal route between two locations using a Dijkstra's algorithm on a database graph.
    
    This algorithm considers travel times, delays, and penalties for transfers between different routes and agencies.

    - 8-minute penalty for changing between different transport agencies.
    - 8-minute penalty for changing routes within the same transport agency.

    Returns a tuple containing:
    - The estimated total time in seconds (float), including penalties.
    - A list of dictionaries, where each dictionary represents a step in the route.
    """
    with Session(engine) as session:
        start_stations_query = session.query(RouteStation).filter(RouteStation.name == start_name)
        if start_agency:
            start_stations_query = start_stations_query.join(RouteName).join(TransportAgency).filter(TransportAgency.name == start_agency)
        start_stations = start_stations_query.options(joinedload(RouteStation.route).joinedload(RouteName.agency)).all()

        end_stations_query = session.query(RouteStation).filter(RouteStation.name == end_name)
        if end_agency:
            end_stations_query = end_stations_query.join(RouteName).join(TransportAgency).filter(TransportAgency.name == end_agency)
        end_stations = end_stations_query.options(joinedload(RouteStation.route).joinedload(RouteName.agency)).all()

        if not start_stations or not end_stations:
            logging.warning("Start or end station not found.")
            return None, None

        best_time = float('inf')
        best_route = None

        for start_station in start_stations:
            for end_station in end_stations:
                if start_station.id == end_station.id:
                    continue
                
                time, route = _dijkstra_search(session, start_station, end_station)
                if time is not None and time < best_time:
                    best_time = time
                    best_route = route
        
        if best_route:
            return best_time, best_route

        return None, None

def _dijkstra_search(session: Session, start_station: RouteStation, end_station: RouteStation) -> Tuple[Optional[float], Optional[List[dict]]]:
    """Dijkstra's algorithm to find the fastest path between two stations."""
    
    # state: (station_id, agency_id, route_id)
    # distances: {state: total_time}
    # pq: [(total_time, state)]
    
    start_state = (start_station.id, start_station.route.agency_id, start_station.route_id)
    
    distances: dict[tuple[int, int, int], float] = {start_state: 0.0}
    previous: dict[tuple[int, int, int], Optional[tuple[int, int, int]]] = {start_state: None}
    route_info: dict = {}

    pq: list[tuple[float, tuple[int, int, int]]] = [(0.0, start_state)]
    visited = set()

    agency_change_penalty = 480.0  # 8 minutes in seconds
    route_change_penalty = 480.0    # 8 minutes in seconds

    while pq:
        current_dist, current_state = heapq.heappop(pq)
        current_station_id, last_agency_id, last_route_id = current_state

        if current_state in visited:
            continue
        
        visited.add(current_state)

        if current_station_id == end_station.id:
            # Reconstruct path
            path = []
            curr = current_state
            while curr:
                path.append(route_info.get(curr))
                curr = previous.get(curr)
            path.reverse()
            
            # First element is None because it's the start, so we remove it
            return current_dist, path[1:]

        # Get all journeys from the current station
        journeys = session.query(RouteJourney).filter(
            (RouteJourney.origin_station_id == current_station_id) |
            (RouteJourney.destination_station_id == current_station_id)
        ).all()

        for journey in journeys:
            if journey.origin_station_id == current_station_id:
                neighbor_station_id = journey.destination_station_id
            else:
                neighbor_station_id = journey.origin_station_id

            neighbor_station = session.query(RouteStation).options(
                joinedload(RouteStation.route).joinedload(RouteName.agency)
            ).filter(RouteStation.id == neighbor_station_id).one()

            new_agency_id = neighbor_station.route.agency_id
            new_route_id = neighbor_station.route_id
            
            new_state = (neighbor_station_id, new_agency_id, new_route_id)

            if new_state in visited:
                continue

            journey_time_seconds = journey.time_of_journey.hour * 3600 + journey.time_of_journey.minute * 60 + journey.time_of_journey.second
            travel_time = float(journey_time_seconds + (journey.delay*60))

            transfer_penalty = 0.0
            is_transfer = False
            if last_agency_id is not None:
                if last_agency_id != new_agency_id:
                    transfer_penalty = agency_change_penalty
                    is_transfer = True
                elif last_route_id != new_route_id:
                    transfer_penalty = route_change_penalty
                    is_transfer = True
            
            new_distance = current_dist + travel_time + transfer_penalty

            if new_state not in distances or new_distance < distances[new_state]:
                distances[new_state] = new_distance
                previous[new_state] = current_state
                
                from_station_data = session.query(
                    RouteStation.name, func.ST_Y(RouteStation.location), func.ST_X(RouteStation.location)
                ).filter(RouteStation.id == current_station_id).one()
                
                neighbor_station_data = session.query(
                    RouteStation.name, func.ST_Y(RouteStation.location), func.ST_X(RouteStation.location)
                ).filter(RouteStation.id == neighbor_station_id).one()

                route_info[new_state] = {
                    'from': {
                        "name": from_station_data[0],
                        "latitude": from_station_data[1],
                        "longitude": from_station_data[2]
                    },
                    'to': {
                        "name": neighbor_station_data[0],
                        "latitude": neighbor_station_data[1],
                        "longitude": neighbor_station_data[2]
                    },
                    'from_display': from_station_data[0],
                    'to_display': neighbor_station_data[0],
                    'time': travel_time,
                    'transfer_penalty': transfer_penalty,
                    'is_transfer': is_transfer,
                    'route_info': {
                        'agency': neighbor_station.route.agency.name,
                        'route_long': neighbor_station.route.name,
                        'route_short': neighbor_station.route.short_name
                    }
                }
                heapq.heappush(pq, (new_distance, new_state))
    
    return None, None
