# Main application file for the FastAPI backend
from .artificial_intelligence.functions import get_openai_client
from .database.functions import get_all_mastodon_posts, get_all_news_articles, get_engine, get_all_media_posts, process_all_unprocessed_posts, get_all_reddit_posts
from .social_media.functions import scrape_all_news, log_into_reddit, scrape_all_reddit_news, scrape_all_mastodon_news

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi_utils.tasks import repeat_every

import os
import logging
import asyncio
    
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

# Get reddit instance from environment variables
REDDIT_CLIENT_ID = os.getenv("REDDIT_CLIENT_ID", "")
REDDIT_CLIENT_SECRET = os.getenv("REDDIT_CLIENT_SECRET", "")
REDDIT_USER_AGENT = os.getenv("REDDIT_USER_AGENT", "")
if not all([REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET, REDDIT_USER_AGENT]):
    logger.error("Reddit API credentials are not fully set in environment variables.")
    raise ValueError("Reddit API credentials are required")
reddit = log_into_reddit(REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET, REDDIT_USER_AGENT)

## Cron to scrape news every hour

@repeat_every(seconds=3600)
async def scrape_news():
    logger.info("Scraping news articles...")
    await asyncio.to_thread(scrape_all_news, dbEngine)

## Cron to scrape Reddit every day
# This is slower because the posts are pulled from top posts of the week

@repeat_every(seconds=86400)
async def scrape_reddit():
    logger.info("Scraping Reddit posts...")
    await asyncio.to_thread(scrape_all_reddit_news, dbEngine, reddit)

## Cron to scrape Mastodon every day

@repeat_every(seconds=86400)
async def scrape_mastodon():
    logger.info("Scraping Mastodon posts...")
    await asyncio.to_thread(scrape_all_mastodon_news, dbEngine)

# Cron to process unprocessed posts every 15 minutes

@repeat_every(seconds=900)
async def process_unprocessed_posts():
    logger.info("Processing unprocessed posts...")
    await asyncio.to_thread(process_all_unprocessed_posts, dbEngine, openaiClient)

# Set up FastAPI app
app = FastAPI()

@app.get("/sync/all")
async def sync_all():
    """
    Endpoint to manually trigger scraping and processing.
    """
    await scrape_news()
    await scrape_reddit()
    await scrape_mastodon()
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

@app.get("/sync/reddit")
async def sync_reddit():
    """
    Endpoint to manually trigger Reddit scraping.
    """
    await scrape_reddit()
    return {"status": "Reddit sync completed"}

@app.get("/sync/mastodon")
async def sync_mastodon():
    """
    Endpoint to manually trigger Mastodon scraping.
    """
    await scrape_mastodon()
    return {"status": "Mastodon sync completed"}

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

@app.get("/api/posts/reddit")
async def get_reddit_posts():
    """
    Endpoint to retrieve all Reddit posts.
    """
    posts = get_all_reddit_posts(dbEngine)
    return {"posts": [post.__dict__ for post in posts]}

@app.get("/api/posts/mastodon")
async def get_mastodon_posts():
    """
    Endpoint to retrieve all Mastodon posts.
    """
    posts = get_all_mastodon_posts(dbEngine)
    return {"posts": [post.__dict__ for post in posts]}
