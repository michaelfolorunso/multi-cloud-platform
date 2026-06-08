# slim keeps the image small, less to pull, less to scan for vulnerabilities
FROM python:3.11-slim

WORKDIR /app

# copying requirements before the rest of the code is intentional
# docker caches layers so a code change won't trigger a full pip reinstall
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# never run as root inside a container
# if the app gets compromised the blast radius stays limited
RUN adduser --disabled-password --gecos "" appuser
USER appuser

# 0.0.0.0 is required, without it kubernetes cant route traffic to the pod
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]