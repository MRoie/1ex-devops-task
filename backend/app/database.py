from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/app")
engine = create_engine(DATABASE_URL, echo=False, future=True)
Base = declarative_base()
