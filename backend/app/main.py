# Main application file for the FastAPI backend
from .db.functions import get_engine, create_user_location
from .db.initialize import import_from_csv
from .db.models import RouteName

from dotenv import load_dotenv
from fastapi import FastAPI
from sqlalchemy.orm import Session

import os
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

# Get the database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL")
dbEngine = get_engine(DATABASE_URL if DATABASE_URL is not None else "sqlite:///./test.db")

# Set up FastAPI app
app = FastAPI()

# If table is empty, import data from CSV
with Session(dbEngine) as session:
    route_count = session.query(RouteName).count()
    if route_count == 0:
        logger.info("No routes found in database. Importing from CSV...")
        import_from_csv(dbEngine, './gtfs/transit_graph.csv')
        logger.info("Import completed.")
    else:
        logger.info(f"Database already has {route_count} routes. Skipping import.")

# User information endpoints

# Endpoint to receive user location data
@app.post("/api/user/location")
async def receive_user_location(data: dict):
    """
    Endpoint to receive user location data.
    Expects a JSON payload with 'latitude' and 'longitude'.

    {
        "user_id": "randomized_user_id_12345",
        "latitude": 19.4326,
        "longitude": -99.1332
    }
    """
    logger.debug(f"Received location data: {data}")

    latitude = data.get("latitude")
    longitude = data.get("longitude")
    user_id = data.get("user_id")

    if latitude is None or longitude is None or user_id is None:
        logger.error("Missing latitude, longitude, or user_id")
        return {"status": "error", "message": "Missing latitude, longitude, or user_id"}
    
    if not isinstance(latitude, (float, int)) or not isinstance(longitude, (float, int)):
        logger.error("Latitude and longitude must be numbers")
        return {"status": "error", "message": "Latitude and longitude must be numbers"}

    if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
        logger.error("Latitude or longitude out of range")
        return {"status": "error", "message": "Latitude or longitude out of range"}

    create_user_location(dbEngine, user_id, latitude, longitude)

    return {"status": "success", "message": "Location received"}
