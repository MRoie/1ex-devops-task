from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Check if we're running in a CI environment
IS_CI = os.getenv("CI") is not None

# Define database configuration
if IS_CI:
    # For CI, use SQLite in-memory database
    print("Running in CI environment, using SQLite in-memory database")
    DATABASE_URL = "sqlite:///:memory:"
    connect_args = {"check_same_thread": False}
else:
    # For normal operation, use PostgreSQL from environment variable
    DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/app")
    connect_args = {}

# Create engine but don't connect immediately
engine = create_engine(DATABASE_URL, echo=False, future=True, connect_args=connect_args)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Utility function to initialize the database
def init_db():
    Base.metadata.create_all(bind=engine)
