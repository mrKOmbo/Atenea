# Database functions

import logging
import time
from datetime import date
from openai import OpenAI
from sqlalchemy import create_engine, Engine, or_
from sqlalchemy.orm import Session

from ..artificial_intelligence.functions import is_post_related, get_keywords_from_post
from .models import Base, MediaPost, NewsArticle, RedditPost, MastodonPost

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

                # If the article is related to the World Cup 2026, save it as a media post
                if is_post_related(openai_client, post, RELATED_KEYWORDS):
                    if post.keywords == "":
                        post.keywords = get_keywords_from_post(openai_client, post)

                    session.add(post)

                # Mark the article as processed
                article.processed = True

                session.commit()

                logger.info(f"Processed article: {article.title}")
            except Exception as e:
                logger.error(f"Error processing article {article.title}: {e}")
                session.rollback()

            time.sleep(1)

    # Get all unprocessed Reddit posts
    with Session(engine) as session:
        unprocessed_reddit_posts = session.query(RedditPost).filter_by(processed=False).all()

        for reddit_post in unprocessed_reddit_posts:
            try:
                # Check if the Reddit post is already in MediaPost to avoid duplicates
                if session.query(MediaPost).filter(MediaPost.url == reddit_post.url).first() is not None:
                    reddit_post.processed = True
                    session.commit()
                    logger.debug(f"Reddit post already processed and in MediaPost: {reddit_post.url}")

                post = MediaPost(
                    source="reddit",
                    url=reddit_post.url,
                    title=reddit_post.title,
                    author=reddit_post.author,
                    content=reddit_post.content,
                    image="",
                    date=reddit_post.date,
                    likes=reddit_post.upvotes,
                    keywords=""
                )

                # If the Reddit post is related to the World Cup 2026, save it as a media post
                if is_post_related(openai_client, post, RELATED_KEYWORDS):
                    post.keywords = get_keywords_from_post(openai_client, post)

                    session.add(post)

                # Mark the Reddit post as processed
                reddit_post.processed = True

                session.commit()

                logger.info(f"Processed Reddit post: {reddit_post.title}")
            except Exception as e:
                logger.error(f"Error processing Reddit post {reddit_post.title}: {e}")
                session.rollback()

            time.sleep(1)

    # Get all unprocessed Mastodon posts
    with Session(engine) as session:
        unprocessed_mastodon_posts = session.query(MastodonPost).filter_by(processed=False).all()

        for mastodon_post in unprocessed_mastodon_posts:
            try:
                # Check if the Mastodon post is already in MediaPost to avoid duplicates
                if session.query(MediaPost).filter(MediaPost.url == mastodon_post.url).first() is not None:
                    mastodon_post.processed = True
                    session.commit()
                    logger.debug(f"Mastodon post already processed and in MediaPost: {mastodon_post.url}")

                post = MediaPost(
                    source="mastodon",
                    url=mastodon_post.url,
                    title="Mastodon Post",
                    author=mastodon_post.author,
                    content=mastodon_post.content,
                    image=mastodon_post.image if mastodon_post.image else "",
                    date=mastodon_post.date,
                    keywords=""
                )

                # If the Mastodon post is related to the World Cup 2026, save it as a media post
                if is_post_related(openai_client, post, RELATED_KEYWORDS):
                    post.keywords = get_keywords_from_post(openai_client, post)

                    session.add(post)

                # Mark the Mastodon post as processed
                mastodon_post.processed = True

                session.commit()

                logger.info(f"Processed Mastodon post by: {mastodon_post.author}")
            except Exception as e:
                logger.error(f"Error processing Mastodon post by {mastodon_post.author}: {e}")
                session.rollback()

            time.sleep(1)

def get_all_media_posts(
    engine: Engine,
    min_likes: int = 0,
    start_date: date | None = None,
    end_date: date | None = None,
    keywords: str | None = None,
    source: str | None = None,
    author: str | None = None,
) -> list[MediaPost]:
    """
    Retrieve all media posts from the database with optional filters.
    """
    with Session(engine) as session:
        query = session.query(MediaPost)

        if min_likes > 0:
            query = query.filter(MediaPost.likes >= min_likes)

        if start_date:
            query = query.filter(MediaPost.date >= start_date)

        if end_date:
            query = query.filter(MediaPost.date <= end_date)

        if keywords:
            keyword_list = [keyword.strip() for keyword in keywords.split(",")]
            query = query.filter(or_(*[MediaPost.keywords.ilike(f"%{keyword}%") for keyword in keyword_list]))

        if source:
            query = query.filter(MediaPost.source.ilike(f"%{source}%"))

        if author:
            query = query.filter(MediaPost.author.ilike(f"%{author}%"))

        posts = query.all()
        return posts

def get_all_news_articles(engine: Engine) -> list[NewsArticle]:
    """
    Retrieve all news articles from the database.
    """
    with Session(engine) as session:
        logger.info("Fetching all news articles from the database")
        articles = session.query(NewsArticle).all()
        return articles

def get_all_reddit_posts(engine: Engine) -> list[RedditPost]:
    """
    Retrieve all Reddit posts from the database.
    """
    with Session(engine) as session:
        logger.info("Fetching all Reddit posts from the database")
        posts = session.query(RedditPost).all()
        return posts

def get_all_mastodon_posts(engine: Engine) -> list[MastodonPost]:
    """
    Retrieve all Mastodon posts from the database.
    """
    with Session(engine) as session:
        logger.info("Fetching all Mastodon posts from the database")
        posts = session.query(MastodonPost).all()
        return posts
