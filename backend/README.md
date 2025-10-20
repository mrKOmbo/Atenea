# Social Media Integration Backend

This backend service is built using FastAPI and SQLAlchemy, providing a robust API for
managing social posts and news related to the Football World Cup 2026.

## Features

- News pulling from various sources
- News classification using artificial intelligence to determine relevance to the World Cup
- Social media post pulling and classification
- Social media post classification using artificial intelligence to determine relevance to the World Cup
- RESTful API for accessing and managing data

## Technologies Used

- FastAPI
- SQLAlchemy
- PostgreSQL

## Setup Instructions

```bash
sudo docker compose up .
```

## API Documentation

### Sync Endpoints

These endpoints are used to manually trigger the scraping and processing of data.

- **GET /sync/all**: Trigger all scraping and processing jobs.
  ```bash
  curl -X GET "https://api.ks32.dev/sync/all"
  ```

- **GET /sync/process**: Trigger the processing of unprocessed posts.
  ```bash
  curl -X GET "https://api.ks32.dev/sync/process"
  ```

- **GET /sync/news**: Trigger news scraping.
  ```bash
  curl -X GET "https://api.ks32.dev/sync/news"
  ```

- **GET /sync/reddit**: Trigger Reddit scraping.
  ```bash
  curl -X GET "https://api.ks32.dev/sync/reddit"
  ```

- **GET /sync/mastodon**: Trigger Mastodon scraping.
  ```bash
  curl -X GET "https://api.ks32.dev/sync/mastodon"
  ```

### API Endpoints

These endpoints are used to retrieve data from the database.

- **GET /api/posts**: Retrieve all media posts with optional filters.
  
  - **Without filters**:
    ```bash
    curl -X GET "https://api.ks32.dev/api/posts"
    ```

  - **With filters**:
    - `min_likes` (integer): Minimum number of likes.
    - `start_date` (string: YYYY-MM-DD): Start date for filtering.
    - `end_date` (string: YYYY-MM-DD): End date for filtering.
    - `keywords` (string): Comma-separated keywords.
    - `source` (string): Source of the posts (e.g., `news`, `reddit`).
    - `author` (string): Author of the posts.

    Example:
    ```bash
    curl -X GET "https://api.ks32.dev/api/posts?min_likes=100&start_date=2025-01-01&end_date=2025-12-31&keywords=soccer,fifa&source=reddit&author=testuser"
    ```

- **GET /api/posts/news**: Retrieve all news posts.
  ```bash
  curl -X GET "https://api.ks32.dev/api/posts/news"
  ```

- **GET /api/posts/reddit**: Retrieve all Reddit posts.
  ```bash
  curl -X GET "https://api.ks32.dev/api/posts/reddit"
  ```

- **GET /api/posts/mastodon**: Retrieve all Mastodon posts.
  ```bash
  curl -X GET "https://api.ks32.dev/api/posts/mastodon"
  ```

