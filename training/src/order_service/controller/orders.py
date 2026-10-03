from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from order_service.database import get_db, query_count
from order_service.repository import OrderRepository
from order_service.schema import OrderResponse
from order_service.service import OrderService

router = APIRouter()
db_dependency = Depends(get_db)


@router.get("/orders", response_model=list[OrderResponse])
def list_orders(
    request: Request,
    db: Session = db_dependency,
) -> list[OrderResponse]:
    result = OrderService(OrderRepository(db)).list_orders()
    request.state.query_count = query_count.get()
    return result
