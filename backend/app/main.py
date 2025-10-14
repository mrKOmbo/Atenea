# Main application file for the FastAPI backend
from .db.functions import get_engine, create_user_location, create_incident_type, create_incident_location, deactivate_old_incident_locations
from .db.initialize import initialize_database_data

from dotenv import load_dotenv
from fastapi import FastAPI

import os
import logging
import schedule
import threading
import time

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

# Get the database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL")
dbEngine = get_engine(DATABASE_URL if DATABASE_URL is not None else "sqlite:///./test.db")
initialize_database_data(dbEngine, './gtfs/transit_graph.csv')

# Set up FastAPI app
app = FastAPI()

# Cron jobs would be set up here if needed
def run_cron_jobs():
    """
    Function to run periodic tasks, such as deactivating old incidents.
    This function can be scheduled to run at regular intervals using a task scheduler.
    """
    logger.info("Running cron jobs...")
    deactivate_old_incident_locations(dbEngine)

# Schedule the cron job to run every hour
schedule.every().hour.do(run_cron_jobs)

# Function to run the scheduler in a separate thread
def run_scheduler():
    """
    Function to run the scheduler in a separate thread.
    """
    while True:
        schedule.run_pending()
        time.sleep(1)

# Start the scheduler in a background thread
scheduler_thread = threading.Thread(target=run_scheduler)
scheduler_thread.daemon = True
scheduler_thread.start()

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

# Incident reporting endpoints

# Endpoint to receive new incident types
@app.post("/api/incident/type")
async def receive_incident_type(data: dict):
    """
    Endpoint to receive new incident types.
    Expects a JSON payload with 'type', 'description', 'severity', and 'estimated_time'.

    {
        "type": "Accident",
        "description": "A minor accident on the main road.",
        "severity": 2,
        "estimated_time": 30
    }
    """
    logger.debug(f"Received incident type data: {data}")

    type = data.get("type")
    description = data.get("description")
    severity = data.get("severity")
    estimated_time = data.get("estimated_time")

    if not type or not description or severity is None or estimated_time is None:
        logger.error("Missing required fields")
        return {"status": "error", "message": "Missing required fields"}

    if not isinstance(severity, int) or not isinstance(estimated_time, int):
        logger.error("Severity and estimated_time must be integers")
        return {"status": "error", "message": "Severity and estimated_time must be integers"}

    if not (1 <= severity <= 10):
        logger.error("Severity must be between 1 and 10")
        return {"status": "error", "message": "Severity must be between 1 and 10"}

    if estimated_time < 0:
        logger.error("Estimated time must be non-negative")
        return {"status": "error", "message": "Estimated time must be non-negative"}

    
    create_incident_type(dbEngine, type, description, severity, estimated_time)

    return {"status": "success", "message": "Incident type received"}

# Endpoint to get all incident types
@app.get("/api/incident/types")
async def get_incident_types():
    """
    Endpoint to retrieve all incident types.
    """
    from .db.functions import get_incident_types
    types = get_incident_types(dbEngine)
    return {"incident_types": [ {"id": t.id, "type": t.type, "description": t.description, "severity": t.severity, "estimated_time": t.estimated_time} for t in types ]}

# Endpoint to receive new incident locations
@app.post("/api/incident/location")
async def receive_incident_location(data: dict):
    """
    Endpoint to receive new incident locations.
    Expects a JSON payload with 'type_id', 'latitude', and 'longitude'.

    {
        "type_id": 1,
        "latitude": 19.4326,
        "longitude": -99.1332
    }
    """
    logger.debug(f"Received incident location data: {data}")

    type_id = data.get("type_id")
    latitude = data.get("latitude")
    longitude = data.get("longitude")

    if type_id is None or latitude is None or longitude is None:
        logger.error("Missing type_id, latitude, or longitude")
        return {"status": "error", "message": "Missing type_id, latitude, or longitude"}
    
    if not isinstance(type_id, int):
        logger.error("type_id must be an integer")
        return {"status": "error", "message": "type_id must be an integer"}

    if not isinstance(latitude, (float, int)) or not isinstance(longitude, (float, int)):
        logger.error("Latitude and longitude must be numbers")
        return {"status": "error", "message": "Latitude and longitude must be numbers"}

    if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
        logger.error("Latitude or longitude out of range")
        return {"status": "error", "message": "Latitude or longitude out of range"}

    create_incident_location(dbEngine, type_id, latitude, longitude)

    return {"status": "success", "message": "Incident location received"}
