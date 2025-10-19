# AI-related functions and utilities
from openai import OpenAI
from ..database.models import MediaPost
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

def is_post_related(client: OpenAI, post: MediaPost, keywords: list[str]) -> bool:
    """
    Use the OpenAI API to determine if a media post is related to the given keywords.
    Returns True if related, False otherwise.
    """
    prompt = f"""Determine if the following media post is related to these keywords:
        Keywords: {', '.join(keywords)}
        Post Title: {post.title}
        Post Content: {post.content}
        Answer 'yes' or 'no'."""
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
        logger.warning(f"OpenAI returned no content for post '{post.title}'")
        return False

    content = content.strip().lower()
    logger.debug(f"OpenAI response for post title '{post.title}': {content}")

    return content == "yes"
