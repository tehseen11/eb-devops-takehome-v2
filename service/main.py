import os
import socket

from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()


@app.get("/")
def home():
    return JSONResponse(
        {
            "app": os.getenv("APP_NAME", "unknown"),
            "version": os.getenv("VERSION", "unknown"),
            "pod": socket.gethostname(),
        }
    )


@app.get("/healthz")
def health():
    return {"status": "healthy"}