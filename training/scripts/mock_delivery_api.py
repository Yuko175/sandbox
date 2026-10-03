import asyncio

from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(title="Delivery API Mock")

# 同時実行数は外部APIの制約であるため、方式設計書記載の値に合わせる。
MAX_CONCURRENCY = 10
_current_requests = 0
_counter_lock = asyncio.Lock()


@app.get("/delivery-status/{order_id}", response_model=None)
async def get_delivery_status(order_id: int) -> dict[str, object] | JSONResponse:
    global _current_requests

    async with _counter_lock:
        if _current_requests >= MAX_CONCURRENCY:
            return JSONResponse(
                status_code=429,
                content={
                    "error": "too_many_requests",
                    "message": "concurrency limit exceeded",
                },
            )
        _current_requests += 1

    try:
        await asyncio.sleep(1)
        # 動作確認用として、常に "delivered" を返すようにしている。
        return {"order_id": order_id, "status": "delivered"}
    finally:
        async with _counter_lock:
            _current_requests -= 1


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=9000)
