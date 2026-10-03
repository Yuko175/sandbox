from pydantic import BaseModel, ConfigDict


class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    orderId: int
    userId: int
    userName: str
    status: str
    totalAmount: int
