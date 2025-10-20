# Database models using SQLAlchemy ORM

from datetime import datetime, timezone
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass

class NewsArticle(Base):
    """
    Table to store news articles, this will be used to track all scraped news articles.
    1. id: Primary key (integer)
    2. title: Title of the news article (string)
    3. author: Author of the news article (string)
    4. publish_date: Date when the article was published (datetime)
    5. content: Full content of the news article (text)
    6. url: URL of the news article (string)
    7. image: URL of the main image of the article (string)
    8. keywords: Keywords associated with the article (string)
    9. processed: Boolean indicating if the article has been processed by AI (default: False)
    """
    __tablename__ = "news_articles"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(nullable=False)
    author: Mapped[str] = mapped_column(nullable=False)
    publish_date: Mapped[datetime] = mapped_column(nullable=False, default=datetime.now(timezone.utc))
    content: Mapped[str] = mapped_column(nullable=False)
    url: Mapped[str] = mapped_column(nullable=False, unique=True)
    image: Mapped[str] = mapped_column(nullable=False)
    keywords: Mapped[str] = mapped_column(nullable=False)
    processed: Mapped[bool] = mapped_column(nullable=False, default=False)

class RedditPost(Base):
    """
    Table to store Reddit posts.
    1. id: Primary key (integer)
    2. reddit_id: Reddit post ID (string)
    3. title: Title of the Reddit post (string)
    4. author: Author of the Reddit post (string)
    5. content: Full content of the Reddit post (text)
    6. url: URL of the Reddit post (string)
    7. subreddit: Subreddit where the post was made (string)
    8. date: Date when the post was created (datetime)
    9. upvotes: Number of upvotes on the post (integer)
    10. processed: Boolean indicating if the post has been processed by AI (default: False)
    """
    __tablename__ = "reddit_posts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    reddit_id: Mapped[str] = mapped_column(nullable=False, unique=True)
    title: Mapped[str] = mapped_column(nullable=False)
    author: Mapped[str] = mapped_column(nullable=False)
    content: Mapped[str] = mapped_column(nullable=False)
    url: Mapped[str] = mapped_column(nullable=False, unique=True)
    subreddit: Mapped[str] = mapped_column(nullable=False)
    date: Mapped[datetime] = mapped_column(nullable=False)
    upvotes: Mapped[int] = mapped_column(nullable=False, default=0)
    processed: Mapped[bool] = mapped_column(nullable=False, default=False)

class MediaPost(Base):
    """
    Table to store generic media posts, this is a unified table for various media types.
    It is used to store the post after being processed by the AI.
    1. id: Primary key (integer)
    2. source: Source of the media post (string, e.g., 'instagram', 'news')
    3. url: URL of the media post (string)
    4. title: Title or caption of the media post (string)
    5. author: Author or username of the media post (string)
    6. content: Full content of the media post (text)
    7. image: URL of the main image of the post (string)
    8. date: Date when the post was created or published (datetime)
    9. likes: Number of likes on the post (integer)
    10. keywords: Keywords associated with the post (string)
    """
    __tablename__ = "media_posts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    source: Mapped[str] = mapped_column(nullable=False)
    url: Mapped[str] = mapped_column(nullable=False, unique=True)
    title: Mapped[str] = mapped_column(nullable=False)
    author: Mapped[str] = mapped_column(nullable=False)
    content: Mapped[str] = mapped_column(nullable=False)
    image: Mapped[str] = mapped_column(nullable=True)
    date: Mapped[datetime] = mapped_column(nullable=False, default=datetime.now(timezone.utc))
    likes: Mapped[int] = mapped_column(nullable=True, default=0)
    keywords: Mapped[str] = mapped_column(nullable=True)
