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

# allows the React frontend to talk to the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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