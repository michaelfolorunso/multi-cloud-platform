from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# pulled from environment (never hardcoded)
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://nexcloud_app:password@localhost:5432/nexcloud"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    # yields a db session and closes it when done, also if something crashes it will close the session 
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()