# Social Media Integration Functions

import newspaper
import feedparser
import instaloader
import logging
from datetime import datetime

from sqlalchemy import Engine
from sqlalchemy.orm import Session

from ..database.models import NewsArticle, InstagramPost

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

NEWS_RSS_FEEDS = [
    "https://www.excelsior.com.mx/rss.xml",
    "https://www.reforma.com/rss/portada.xml",
    "https://heraldodemexico.com.mx/rss",
    "https://www.eleconomista.com.mx/rss.html",
    "https://www.proceso.com.mx/rss/",
    "https://editorial.aristeguinoticias.com/category/mexico/feed/",
    "https://www.meganoticias.mx/cdmx/rss",
    "https://mexiconewsdaily.com/feed",
    "https://www.sinembargo.mx/feed"
]

INSTAGRAM_USERS = [
    'm_de_milo',
    "fifaworldcup",
    "fifa_world.cup26",
    "mexicocity26_",
    "fwc26miami",
    "losangelesfwc26",
    "fwc26monterrey",
    "gdl2026",
    "fwc26atlanta",
    "fifa",
    "leaguescup"
]

def scrape_news_from_feed(engine: Engine, feed_url: str) -> None:
    """
    Scrape news articles from a given RSS feed URL, and store them in the database if they are not already present.
    Each article is represented as a dictionary with keys: title, author, publish_date, content, url, image, keywords.
    """
    feed = feedparser.parse(feed_url)

    with Session(engine) as session:

        for entry in feed.entries:
            if entry.link is None:
                logger.warning("Entry without link found, skipping.")
                continue

            url = str(entry.link) if not isinstance(entry.link, str) else entry.link
            if session.query(NewsArticle).filter(NewsArticle.url == url).first() is not None:
                logger.debug(f"Article already in database: {url}")
                continue

            article = newspaper.Article(url)
            article.download()
            article.parse()
            # Ensure publish_date is a datetime object
            if article.publish_date:
                publish_date = article.publish_date
            elif hasattr(entry, "published_parsed") and entry.published_parsed:
                publish_date = datetime(*entry.published_parsed[:6])
            else:
                publish_date = None

            new_article = NewsArticle(
                title=article.title,
                author=article.authors[0] if article.authors else "Unknown",
                publish_date=publish_date,
                content=article.text,
                url=url,
                image=article.top_image if article.top_image else "",
                keywords=", ".join(article.keywords) if article.keywords else "",
                processed=False
            )
            session.add(new_article)
            logger.info(f"Added new article to database: {url}")

        session.commit()
        logger.info("All new articles have been committed to the database.")

def scrape_all_news(engine: Engine) -> None:
    """
    Scrape news articles from all predefined RSS feeds and store them in the database.
    """
    for feed_url in NEWS_RSS_FEEDS:
        logger.info(f"Scraping news from feed: {feed_url}")
        scrape_news_from_feed(engine, feed_url)

def instagram_login(user: str, csrf_token: str, session_id: str, ds_user_id: str, mid: str, ig_did: str) -> instaloader.Instaloader:
    """
    Log into Instagram using provided credentials and return an Instaloader instance.
    """
    instaloader_instance = instaloader.Instaloader()

    try:
        instaloader_instance.load_session(
            user, {
                "csrftoken": csrf_token,
                "sessionid": session_id,
                "ds_user_id": ds_user_id,
                "mid": mid,
                "ig_did": ig_did
            }
        )

        if instaloader_instance.test_login() == user:
            logger.info("Logged into Instagram successfully.")
        else:
            logger.error("Instagram login test failed.")

        return instaloader_instance
    except Exception as e:
        logger.error(f"Error logging into Instagram: {e}")
        return instaloader_instance

def scrape_instagram_user(engine: Engine, instaloader_instance: instaloader.Instaloader, username: str, max_posts: int = 10) -> None:
    """
    Scrape recent posts from a given Instagram user, and store them in the database.
    The post are limited to max_posts, this is to avoid excessive scraping.
    """
    try:
        profile = instaloader.Profile.from_username(instaloader_instance.context, username)
        posts = profile.get_posts()
        count = 0

        with Session(engine) as session:
            for post in posts:
                if count >= max_posts:
                    break

                post_url = post.url
                username = post.owner_username
                caption = post.caption if post.caption else ""
                likes = post.likes
                date = post.date_utc # This is already a datetime object
                keywords = post.caption_hashtags if post.caption_hashtags else ""

                instagram_post = InstagramPost(
                    url=post_url,
                    username=username,
                    caption=caption,
                    likes=likes,
                    date=date,
                    keywords=", ".join(keywords),
                    processed=False
                )

                if session.query(InstagramPost).filter(InstagramPost.url == post_url).first() is None:
                    session.add(instagram_post)
                    session.commit()
                    logger.info(f"Added new Instagram post to database: {post_url}")
                else:
                    logger.debug(f"Instagram post already in database: {post_url}")

                count += 1

    except Exception as e:
        logger.error(f"Error scraping Instagram user {username}: {e}")

def scrape_all_instagram_users(engine: Engine, instaloader_instance: instaloader.Instaloader, max_posts_per_user: int = 10) -> None:
    """
    Scrape recent posts from all predefined Instagram users and store them in the database.
    Each user is limited to max_posts_per_user to avoid excessive scraping.
    """
    for user in INSTAGRAM_USERS:
        logger.info(f"Scraping Instagram user: {user}")
        scrape_instagram_user(engine, instaloader_instance, user, max_posts=max_posts_per_user)
