# Social Media Integration Functions

import feedparser
import logging
import newspaper
import time
from datetime import datetime


from sqlalchemy import Engine
from sqlalchemy.orm import Session

from ..database.models import NewsArticle

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

NEWS_RSS_FEEDS = [
    "https://football-rankings.info/feeds",
    "https://www.independent.co.uk/sport/football/rss",
    "https://www.theguardian.com/football/world-cup/rss",
    "https://www.espn.in/football/league/_/name/fifa-wc/rss",
    "https://www.fifamuseum.com/en/blog-stories/rss",
    "https://www.101greatgoals.com/feed",
    "https://www.90min.com/posts.rss",
    "https://www.soccernews.com/feed",
    "https://www.footballfancast.com/feed",
    "https://www.caughtoffside.com/feed",
    "https://www.foxsports.com/rss-feeds",
    "https://www.foxsports.com/soccer/fifa-world-cup/news",
    "https://www.newsnow.co.uk/h/Sport/Football/International/FIFA+World+Cup",
    "https://www.wizardrss.com/soccer-feeds.html"
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
                time_struct = time.struct_time(entry.published_parsed)
                publish_date = datetime.fromtimestamp(time.mktime(time_struct))
            else:
                publish_date = None

            # Author handling
            author = "Unknown"
            if not article.authors:
                # If no authors found, use the main url domain as author
                author = url.split("/")[2]
            else:
                author = ""
                for a in article.authors:
                    author += a + ", "
                author = author[:-2]  # Remove trailing comma and space

            new_article = NewsArticle(
                title=article.title,
                author=author,
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
