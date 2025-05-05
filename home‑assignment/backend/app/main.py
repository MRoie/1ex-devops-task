from fastapi import FastAPI
from .database import engine, Base

app = FastAPI()

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}
