from sqlalchemy import select
from sqlalchemy.orm import Session

from order_service.model import Order


class OrderRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_orders(self, limit: int = 100) -> list[Order]:
        return list(
            self.db.scalars(select(Order).order_by(Order.id).limit(limit)).all()
        )
