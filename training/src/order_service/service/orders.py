from order_service.repository import OrderRepository
from order_service.schema import OrderResponse


class OrderService:
    def __init__(self, repository: OrderRepository) -> None:
        self.repository = repository

    def list_orders(self) -> list[OrderResponse]:
        orders = self.repository.list_orders()
        result: list[OrderResponse] = []
        for order in orders:
            user = self.repository.find_user(order.user_id)
            if user is None:
                raise LookupError(f"User {order.user_id} was not found")
            result.append(
                OrderResponse(
                    orderId=order.id,
                    userId=order.user_id,
                    userName=user.name,
                    status=order.status,
                    totalAmount=order.total_amount,
                )
            )
        return result
