from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from order_service.database import get_db
from order_service.external import DeliveryApiClient
from order_service.repository import OrderRepository
from order_service.schema import OrderResponse
from order_service.service import OrderService

router = APIRouter()
db_dependency = Depends(get_db)


@router.get("/orders", response_model=list[OrderResponse])
async def list_orders(
    db: Session = db_dependency,
) -> list[OrderResponse]:
    delivery_api_client = DeliveryApiClient()
    return await OrderService(
        OrderRepository(db),
        delivery_api_client,
    ).list_orders()
