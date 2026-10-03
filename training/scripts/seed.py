from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select

from order_service.database import SessionLocal, engine
from order_service.model import Base, Order, User

USER_COUNT = 100
ORDER_COUNT = 2000


def seed() -> None:
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        if db.scalar(select(func.count()).select_from(Order)):
            return
        now = datetime.now(UTC)
        users = [
            User(
                name=f"User {index}",
                email=f"user{index}@example.com",
                created_at=now,
            )
            for index in range(1, USER_COUNT + 1)
        ]
        db.add_all(users)
        db.flush()
        db.add_all(
            [
                Order(
                    user_id=users[index % USER_COUNT].id,
                    status=("CREATED", "PAID", "SHIPPED")[index % 3],
                    total_amount=1000 + (index % 50) * 100,
                    created_at=now - timedelta(minutes=index),
                )
                for index in range(ORDER_COUNT)
            ]
        )
        db.commit()
    print(f"Seeded {USER_COUNT} users and {ORDER_COUNT} orders.")


if __name__ == "__main__":
    seed()
