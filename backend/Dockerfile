FROM python:3.13-slim

WORKDIR /opt

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY ./app /opt/app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
