from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import OperationalError
from database import engine
import models
from routes import projects_router, tasks_router

try:
    models.Base.metadata.create_all(bind=engine)
except OperationalError:
    print("Database not ready yet — will retry on next startup")

app = FastAPI(
    title="Task Flow Pro",
    description="NexCloud demo SaaS — project and task management platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# wildcard origin for dev — production locks this to the actual frontend domain
# e.g. allow_origins=["https://app.nexcloud.io"]
# note: allow_credentials must stay False with wildcard origins — browsers block it otherwise
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: replace with actual domain before production
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

app.include_router(projects_router)
app.include_router(tasks_router)


@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "task-flow-pro-api"}


@app.get("/")
def root():
    return {
        "message": "Task Flow Pro API",
        "version": "1.0.0",
        "docs": "/docs"
    }