from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
import os

# fail loudly if DATABASE_URL is missing rather than silently falling back
# to a credential that will never work outside local dev
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    # yields a db session and closes it when done, also if something crashes it will close the session
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
