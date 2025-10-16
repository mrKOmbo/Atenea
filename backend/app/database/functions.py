# Database functions

import logging
import time
from openai import OpenAI
from sqlalchemy import create_engine, Engine
from sqlalchemy.orm import Session

from ..artificial_intelligence.functions import is_news_article_related, is_instagram_post_related
from .models import Base, MediaPost, NewsArticle, InstagramPost

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)
VICINITY_RADIUS_METERS = 500

RELATED_KEYWORDS = [
    "World Cup 2026",
    "Mundial 2026",
    "FIFA",
    "soccer",
    "football",
]

def get_engine(db_url: str) -> Engine:
    """
    Create and return a SQLAlchemy engine. If the database does not exist, it will be created.
    """
    engine = create_engine(db_url)

    if engine is None:
        logging.error("Failed to create database engine")
        raise ValueError("Failed to create database engine")

    Base.metadata.create_all(engine)
    return engine

def process_all_unprocessed_posts(engine: Engine, openai_client: OpenAI) -> None:
    """
    This function processes all unprocessed news articles and social media posts in the database.
    It uses the OpenAI API to analyze and summarize the content, then stores the results in a unified table.

    For news articles, it checks if they are related to the World Cup 2026 using relevant keywords.
    """

    # Get all unprocessed news articles
    with Session(engine) as session:
        unprocessed_articles = session.query(NewsArticle).filter_by(processed=False).all()

        for article in unprocessed_articles:
            try:
                # Check if the article is already in MediaPost to avoid duplicates
                if session.query(MediaPost).filter(MediaPost.url == article.url).first() is not None:
                    article.processed = True
                    session.commit()
                    logger.debug(f"Article already processed and in MediaPost: {article.url}")

                is_related = is_news_article_related(openai_client, article, RELATED_KEYWORDS)
                if is_related:
                    post = MediaPost(
                        source="news",
                        url=article.url,
                        title=article.title,
                        author=article.author,
                        content=article.content,
                        image=article.image,
                        date=article.publish_date,
                        keywords=article.keywords
                    )
                    session.add(post)

                article.processed = True
                session.commit()

                logger.info(f"Processed article: {article.title}")
            except Exception as e:
                logger.error(f"Error processing article {article.title}: {e}")
                session.rollback()

            time.sleep(1)  # To avoid hitting rate limits

    # Get all unprocessed Instagram posts
    with Session(engine) as session:
        unprocessed_instagram_posts = session.query(InstagramPost).filter_by(processed=False).all()

        for insta_post in unprocessed_instagram_posts:
            try:
                # Check if the post is already in MediaPost to avoid duplicates
                if session.query(MediaPost).filter(MediaPost.url == insta_post.url).first() is not None:
                    insta_post.processed = True
                    session.commit()
                    logger.debug(f"Instagram post already processed and in MediaPost: {insta_post.url}")

                is_related = is_instagram_post_related(openai_client, insta_post, RELATED_KEYWORDS)

                if is_related:
                    post = MediaPost(
                        source="instagram",
                        url=insta_post.url,
                        image=insta_post.image_url,
                        title="Instagram Post",
                        author=insta_post.username,
                        content=insta_post.caption,
                        date=insta_post.date,
                        keywords=insta_post.keywords
                    )
                    session.add(post)

                insta_post.processed = True
                session.commit()

                logger.info(f"Processed Instagram post: {insta_post.url}")
            except Exception as e:
                logger.error(f"Error processing Instagram post {insta_post.url}: {e}")
                session.rollback()



def get_all_media_posts(engine: Engine) -> list[MediaPost]:
    """
    Retrieve all media posts from the database.
    """
    with Session(engine) as session:
        posts = session.query(MediaPost).all()
        return posts

def get_all_news_articles(engine: Engine) -> list[NewsArticle]:
    """
    Retrieve all news articles from the database.
    """
    with Session(engine) as session:
        logger.info("Fetching all news articles from the database")
        articles = session.query(NewsArticle).all()
        return articles
    
def get_all_instagram_posts(engine: Engine) -> list[InstagramPost]:
    """
    Retrieve all Instagram posts from the database.
    """
    with Session(engine) as session:
        logger.info("Fetching all Instagram posts from the database")
        posts = session.query(InstagramPost).all()
        return posts