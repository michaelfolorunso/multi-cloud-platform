# slim keeps the image small, less to pull, less to scan for vulnerabilities
FROM python:3.11-slim

WORKDIR /app

# create the non-root user before copying files so ownership is correct
RUN adduser --disabled-password --gecos "" appuser

# copying requirements before the rest of the code is intentional
# docker caches layers so a code change won't trigger a full pip reinstall
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# transfer ownership of the app directory to appuser
RUN chown -R appuser:appuser /app

# never run as root inside a container
# if the app gets compromised the blast radius stays limited
USER appuser

EXPOSE 8000

# 0.0.0.0 is required, without it kubernetes cant route traffic to the pod
CMD ["python", "-u", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
