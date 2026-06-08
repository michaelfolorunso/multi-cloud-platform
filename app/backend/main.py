from fastapi import FastAPI
from sqlalchemy.exc import OperationalError
from database import engine
import models
from routes import projects_router, tasks_router

# create tables on startup — alembic would handle this in production
try:
    models.Base.metadata.create_all(bind=engine)
except OperationalError:
    # db might not be ready yet on first boot — kubernetes will restart the pod
    print("Database not ready yet — will retry on next startup")

app = FastAPI(
    title="Task Flow Pro",
    description="NexCloud demo SaaS — project and task management platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# register routers
app.include_router(projects_router)
app.include_router(tasks_router)


@app.get("/health")
def health_check():
    # kubernetes liveness and readiness probes hit this endpoint
    return {"status": "healthy", "service": "task-flow-pro-api"}


@app.get("/")
def root():
    return {
        "message": "Task Flow Pro API",
        "version": "1.0.0",
        "docs": "/docs"
    }