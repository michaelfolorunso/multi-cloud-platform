from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


# --- PROJECT SCHEMAS ---

class ProjectCreate(BaseModel):
    name:        str
    description: Optional[str] = None


class ProjectResponse(BaseModel):
    id:          int
    name:        str
    description: Optional[str]
    created_at:  datetime

    class Config:
        from_attributes = True


class ProjectWithTasks(BaseModel):
    id:          int
    name:        str
    description: Optional[str]
    created_at:  datetime
    tasks:       List["TaskResponse"] = []

    class Config:
        from_attributes = True


# --- TASK SCHEMAS ---

class TaskCreate(BaseModel):
    title:       str
    description: Optional[str] = None
    project_id:  int


class TaskUpdate(BaseModel):
    title:       Optional[str] = None
    description: Optional[str] = None
    completed:   Optional[bool] = None


class TaskResponse(BaseModel):
    id:          int
    title:       str
    description: Optional[str]
    completed:   bool
    project_id:  int
    created_at:  datetime

    class Config:
        from_attributes = True


# needed because ProjectWithTasks references TaskResponse before its defined
ProjectWithTasks.model_rebuild()