# AI-related functions and utilities
from openai import OpenAI
from ..database.models import MediaPost, NewsArticle, InstagramPost
import logging

logger = logging.getLogger(__name__)

AI_MODEL = "gemma3:1b"

def get_openai_client(ollama_url: str) -> OpenAI:
    """
    Initialize and return an OpenAI client.
    """
    return OpenAI(
        base_url=ollama_url,
        api_key="ollama",
    )

def is_news_article_related(client: OpenAI, article: NewsArticle, keywords: list[str]) -> bool:
    """
    Use the OpenAI API to determine if a news article title is related to the given keywords.
    Returns True if related, False otherwise.
    """
    prompt = f"Determine if the following news article title is related to these keywords: {', '.join(keywords)}.\n\nTitle: {article.title}\n\nRespond with 'Yes' or 'No'."
    response = client.chat.completions.create(
        model=AI_MODEL,
        messages=[
            {"role": "system", "content": "You are a helpful assistant that classifies news articles."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=10
    )
    content = response.choices[0].message.content
    if content is None:
        logger.warning(f"OpenAI returned no content for article '{article.title}'")
        return False

    content = content.strip().lower()
    logger.debug(f"OpenAI response for article title '{article.title}': {content}")

    return content == "yes"

def is_instagram_post_related(client: OpenAI, post: InstagramPost, keywords: list[str]) -> bool:
    """
    Use the OpenAI API to determine if an Instagram post caption is related to the given keywords.
    Returns True if related, False otherwise.
    """
    prompt = f"Determine if the following Instagram post is related to these keywords: {', '.join(keywords)}.\n\n. Username: {post.username}\n\nCaption: {post.caption}\n\nRespond with 'Yes' or 'No'."
    response = client.chat.completions.create(
        model=AI_MODEL,
        messages=[
            {"role": "system", "content": "You are a helpful assistant that classifies social media posts."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=10
    )
    content = response.choices[0].message.content
    if content is None:
        logger.warning(f"OpenAI returned no content for Instagram post ID '{post.id}'")
        return False

    content = content.strip().lower()
    logger.debug(f"OpenAI response for Instagram post ID '{post.id}': {content}")

    return content == "yes"
