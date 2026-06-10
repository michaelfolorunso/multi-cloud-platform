import redis
import json
import time
import os
from sqlalchemy import create_engine, text

# connecting to same redis and postgres as the backend
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://nexcloud_app:password@localhost:5432/nexcloud")

engine = create_engine(DATABASE_URL)

def get_redis():
    return redis.from_url(REDIS_URL, decode_responses=True)

def process_task_completed(data: dict):
    # when a task is completed we log it to the database
    # in production this could send email notifications, update analytics, etc.
    task_id = data.get("task_id")
    project_id = data.get("project_id")
    print(f"Processing task completion: task_id={task_id}, project_id={project_id}")

    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT title FROM tasks WHERE id = :id"),
            {"id": task_id}
        )
        row = result.fetchone()
        if row:
            print(f"Task '{row[0]}' marked complete in project {project_id}")

def process_project_created(data: dict):
    # when a project is created we could send a welcome email
    # or set up default tasks, etc.
    project_id = data.get("project_id")
    project_name = data.get("name")
    print(f"New project created: '{project_name}' (id={project_id})")

def handle_job(job_type: str, data: dict):
    # routes jobs to the right handler based on type
    handlers = {
        "task_completed": process_task_completed,
        "project_created": process_project_created,
    }
    handler = handlers.get(job_type)
    if handler:
        handler(data)
    else:
        print(f"Unknown job type: {job_type}")

def main():
    print("Worker starting up...")
    cache = get_redis()

    # keeps running forever, checking for new jobs every second
    while True:
        try:
            # blpop blocks until a job appears in the queue
            # timeout=1 means check every second so we can catch keyboard interrupt
            job = cache.blpop("job_queue", timeout=1)

            if job:
                _, payload = job
                data = json.loads(payload)
                job_type = data.get("type")
                print(f"Received job: {job_type}")
                handle_job(job_type, data.get("data", {}))

        except redis.exceptions.ConnectionError:
            # redis might not be ready yet on startup
            print("Redis not available, retrying in 3 seconds...")
            time.sleep(3)
        except Exception as e:
            print(f"Error processing job: {e}")
            time.sleep(1)

if __name__ == "__main__":
    main()