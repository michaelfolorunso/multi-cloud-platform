# same base as backend for consistency
FROM python:3.11-slim

WORKDIR /app

# requirements first so code changes dont trigger a full reinstall
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# no port needed, worker doesnt serve http traffic
# it just reads from redis queue and processes jobs

RUN adduser --disabled-password --gecos "" appuser
USER appuser

CMD ["python", "-u", "main.py"]