from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class Project(Base):
    __tablename__ = "projects"

    id          = Column(Integer, primary_key=True, index=True)
    name        = Column(String, nullable=False)
    description = Column(String, nullable=True)
    created_at  = Column(DateTime, default=datetime.utcnow)

    # one project has many tasks
    tasks = relationship("Task", back_populates="project", cascade="all, delete-orphan")


class Task(Base):
    __tablename__ = "tasks"

    id          = Column(Integer, primary_key=True, index=True)
    title       = Column(String, nullable=False)
    description = Column(String, nullable=True)
    completed   = Column(Boolean, default=False)
    project_id  = Column(Integer, ForeignKey("projects.id"), nullable=False)
    created_at  = Column(DateTime, default=datetime.utcnow)

    # each task belongs to one project
    project = relationship("Project", back_populates="tasks")