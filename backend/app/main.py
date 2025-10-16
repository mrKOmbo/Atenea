# Main application file for the FastAPI backend
from .artificial_intelligence.functions import get_openai_client
from .database.functions import get_all_instagram_posts, get_all_news_articles, get_engine, get_all_media_posts, process_all_unprocessed_posts
from .social_media.functions import scrape_all_news, scrape_all_instagram_users, instagram_login

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi_utils.tasks import repeat_every

import os
import logging
    
# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

# Get the database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL is None:
    logger.error("DATABASE_URL is not set in environment variables.")
    raise ValueError("DATABASE_URL is required")
dbEngine = get_engine(DATABASE_URL)

# Get the ollama URL from environment variables
OLLAMA_URL = os.getenv("OLLAMA_URL")
if OLLAMA_URL is None:
    logger.error("OLLAMA_URL is not set in environment variables.")
    raise ValueError("OLLAMA_URL is required")
openaiClient = get_openai_client(OLLAMA_URL)

# Get instagram credentials from environment variables
INSTAGRAM_USER= os.getenv("INSTAGRAM_USER", "")
INSTAGRAM_CSRFTOKEN= os.getenv("INSTAGRAM_CSRFTOKEN", "")
INSTAGRAM_SESSIONID= os.getenv("INSTAGRAM_SESSIONID", "")
INSTAGRAM_DS_USER_ID= os.getenv("INSTAGRAM_DS_USER_ID", "")
INSTAGRAM_MID= os.getenv("INSTAGRAM_MID", "")
INSTAGRAM_IG_DID= os.getenv("INSTAGRAM_IG_DID", "")
if not INSTAGRAM_USER or not INSTAGRAM_CSRFTOKEN or not INSTAGRAM_SESSIONID or not INSTAGRAM_DS_USER_ID or not INSTAGRAM_MID or not INSTAGRAM_IG_DID:
    logger.error("Instagram credentials are not fully set in environment variables.")
    raise ValueError("All Instagram credentials are required")
instaloader_instance = instagram_login(INSTAGRAM_USER, INSTAGRAM_CSRFTOKEN, INSTAGRAM_SESSIONID, INSTAGRAM_DS_USER_ID, INSTAGRAM_MID, INSTAGRAM_IG_DID)

## Cron to scrape news every hour

@repeat_every(seconds=3600)
async def scrape_news():
    logger.info("Scraping news articles...")
    scrape_all_news(dbEngine)

# Cron to scrape Instagram hashtags every 30 minutes

@repeat_every(seconds=1800)
async def scrape_instagram_users():
    logger.info("Scraping Instagram users...")
    scrape_all_instagram_users(dbEngine, instaloader_instance)

# Cron to process unprocessed posts every 15 minutes

@repeat_every(seconds=900)
async def process_unprocessed_posts():
    logger.info("Processing unprocessed posts...")
    process_all_unprocessed_posts(dbEngine, openaiClient)

# Set up FastAPI app
app = FastAPI()

@app.get("/sync/all")
async def sync_all():
    """
    Endpoint to manually trigger scraping and processing.
    """
    await scrape_news()
    await scrape_instagram_users()
    await process_unprocessed_posts()
    return {"status": "Sync completed"}

@app.get("/sync/process")
async def sync_process():
    """
    Endpoint to manually trigger processing of unprocessed posts.
    """
    await process_unprocessed_posts()
    return {"status": "Processing of unprocessed posts completed"}

@app.get("/sync/news")
async def sync_news():
    """
    Endpoint to manually trigger news scraping.
    """
    await scrape_news()
    return {"status": "News sync completed"}


@app.get("/sync/instagram")
async def sync_instagram():
    """
    Endpoint to manually trigger Instagram user scraping.
    """
    await scrape_instagram_users()
    return {"status": "Instagram sync completed"}

@app.get("/api/posts")
async def get_posts():
    """
    Endpoint to retrieve all media posts.
    """
    posts = get_all_media_posts(dbEngine)
    return {"posts": [post.__dict__ for post in posts]}

@app.get("/api/posts/news")
async def get_news_posts():
    """
    Endpoint to retrieve all news posts.
    """
    posts = get_all_news_articles(dbEngine)
    return {"posts": [post.__dict__ for post in posts]}

@app.get("/api/posts/instagram")
async def get_instagram_posts():
    """
    Endpoint to retrieve all Instagram posts.
    """
    posts = get_all_instagram_posts(dbEngine)
    return {"posts": [post.__dict__ for post in posts]}


