import logging
from time import perf_counter

from fastapi import FastAPI

from order_service.controller import router as order_router
from order_service.database import query_count

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("order_service")

app = FastAPI(title="Order Service")
app.include_router(order_router)


@app.middleware("http")
async def access_log(request, call_next):
    started = perf_counter()
    token = query_count.set(0)
    try:
        response = await call_next(request)
        elapsed_ms = (perf_counter() - started) * 1000
        logger.info(
            "%s %s %s %.2fms queries=%d",
            request.method,
            request.url.path,
            response.status_code,
            elapsed_ms,
            getattr(request.state, "query_count", query_count.get()),
        )
        return response
    finally:
        query_count.reset(token)
