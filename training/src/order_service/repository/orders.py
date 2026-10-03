from sqlalchemy import select
from sqlalchemy.orm import Session

from order_service.model import Order, User


class OrderRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_orders(self) -> list[Order]:
        return list(self.db.scalars(select(Order).order_by(Order.id)).all())

    def find_user(self, user_id: int) -> User | None:
        return self.db.scalar(select(User).where(User.id == user_id))
