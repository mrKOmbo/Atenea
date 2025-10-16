#!/bin/bash

podman build -t atenea .

podman pod create --name atenea-pod -p 9000:8000

podman run -d --replace \
    --name ollama \
    --pod atenea-pod \
    -v /home/core/ollama:/root/.ollama:Z \
    docker.io/ollama/ollama serve

podman run -d --replace  \
    --name atenea-db \
    --pod atenea-pod \
    -e POSTGRES_USER=atenea \
    -e POSTGRES_PASSWORD=atenea \
    -e POSTGRES_DB=atenea \
    -v atenea-db-data:/var/lib/postgresql/data \
    docker.io/library/postgres:latest

podman run -d --replace \
    --name atenea-backend \
    --pod atenea-pod \
    --env-file .env \
    atenea