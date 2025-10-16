FROM python:3.13-slim

WORKDIR /opt

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY ./requirements.txt /app/requirements.txt
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY ./app /opt/app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
