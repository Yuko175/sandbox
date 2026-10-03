from pydantic import BaseModel


class OrderResponse(BaseModel):
    orderId: int
    customerName: str
    deliveryStatus: str
