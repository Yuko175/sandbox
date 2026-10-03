from sqlalchemy import select
from sqlalchemy.orm import Session

from order_service.model import Order


class OrderRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_order(self, order_id: int) -> Order | None:
        return self.db.get(Order, order_id)

    def list_orders(self, limit: int = 100) -> list[Order]:
        return list(
            self.db.scalars(
                select(Order).order_by(Order.update_at.desc(), Order.id.desc()).limit(limit)
            ).all()
        )
