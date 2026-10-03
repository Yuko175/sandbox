from sqlalchemy import func, select

from order_service.database import SessionLocal, engine
from order_service.model import Base, Order

ORDER_COUNT = 100


def seed() -> None:
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        if db.scalar(select(func.count()).select_from(Order)):
            return
        db.add_all(
            [
                Order(id=order_id, customer_name=f"Customer {order_id}")
                for order_id in range(1, ORDER_COUNT + 1)
            ]
        )
        db.commit()
    print(f"Seeded {ORDER_COUNT} orders.")


if __name__ == "__main__":
    seed()
