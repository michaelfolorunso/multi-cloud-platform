from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
import json
import redis
import os

from database import get_db
from models import Project
from schemas import ProjectCreate, ProjectResponse, ProjectWithTasks

router = APIRouter(prefix="/projects", tags=["projects"])

# redis connection — app still works if redis is down
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
try:
    cache = redis.from_url(REDIS_URL, decode_responses=True)
    cache.ping()
except:
    cache = None


@router.post("", response_model=ProjectResponse, status_code=201)
def create_project(project: ProjectCreate, db: Session = Depends(get_db)):
    db_project = Project(**project.model_dump())
    db.add(db_project)
    db.commit()
    db.refresh(db_project)

    # new project means cached list is stale
    if cache:
        cache.delete("projects:all")

    return db_project


@router.get("", response_model=List[ProjectResponse])
def get_projects(db: Session = Depends(get_db)):
    # hit cache first — saves a db round trip on every request
    if cache:
        cached = cache.get("projects:all")
        if cached:
            return json.loads(cached)

    projects = db.query(Project).all()

    if cache:
        cache.setex("projects:all", 300, json.dumps([
            {
                "id": p.id,
                "name": p.name,
                "description": p.description,
                "created_at": p.created_at.isoformat()
            }
            for p in projects
        ]))

    return projects


@router.get("/{project_id}", respon