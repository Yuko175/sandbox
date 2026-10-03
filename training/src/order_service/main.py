import logging
from time import perf_counter

from fastapi import FastAPI

from order_service.controller import router as order_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("order_service")

app = FastAPI(title="Order Service")
app.include_router(order_router)


@app.middleware("http")
async def access_log(request, call_next):
    started = perf_counter()
    response = await call_next(request)
    logger.info(
        "%s %s %s %.2fms",
        request.method,
        request.url.path,
        response.status_code,
        (perf_counter() - started) * 1000,
    )
    return response
