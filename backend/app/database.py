from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Define database URL from environment variable with fallback
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/app")

# Create engine but don't connect immediately
engine = create_engine(DATABASE_URL, echo=False, future=True, connect_args={})

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Utility function to initialize the database
def init_db():
    Base.metadata.create_all(bind=engine)
