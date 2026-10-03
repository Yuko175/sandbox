from order_service.external.delivery_api_client import DeliveryApiClient
from order_service.repository import OrderRepository
from order_service.schema import OrderResponse


class OrderService:
    def __init__(
        self,
        repository: OrderRepository,
        delivery_api_client: DeliveryApiClient,
    ) -> None:
        self.repository = repository
        self.delivery_api_client = delivery_api_client

    async def list_orders(self, limit: int = 100) -> list[OrderResponse]:
        orders = self.repository.list_orders(limit)
        result: list[OrderResponse] = []
        for order in orders:
            delivery = await self.delivery_api_client.get_delivery_status(order.id)
            result.append(
                OrderResponse(
                    orderId=order.id,
                    customerName=order.customer_name,
                    deliveryStatus=str(delivery["status"]),
                )
            )
        return result
