from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from order_service.database import get_db
from order_service.external import DeliveryApiClient
from order_service.repository import OrderRepository
from order_service.schema import OrderResponse
from order_service.service import OrderService

router = APIRouter()
db_dependency = Depends(get_db)


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    db: Session = db_dependency,
) -> OrderResponse:
    delivery_api_client = DeliveryApiClient()
    order = await OrderService(
        OrderRepository(db),
        delivery_api_client,
    ).get_order(order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


@router.get("/orders", response_model=list[OrderResponse])
async def list_orders(
    db: Session = db_dependency,
    limit: int = Query(default=100, ge=1, le=100),
) -> list[OrderResponse]:
    delivery_api_client = DeliveryApiClient()
    return await OrderService(
        OrderRepository(db),
        delivery_api_client,
    ).list_orders(limit=limit)
