import os

import httpx


class DeliveryApiClient:
    def __init__(
        self,
        base_url: str | None = None,
        timeout: float = 5.0,
    ) -> None:
        self.base_url = (
            base_url or os.getenv("DELIVERY_API_BASE_URL", "http://127.0.0.1:9000")
        ).rstrip("/")
        self.timeout = timeout

    async def get_delivery_status(self, order_id: int) -> dict[str, object]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/delivery-status/{order_id}"
            )
            response.raise_for_status()
            return response.json()
