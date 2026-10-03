from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select

from order_service.database import SessionLocal, engine
from order_service.model import Base, Order, User

USER_COUNT = 100_000
ORDER_COUNT = 2_000_000
BATCH_SIZE = 5000


def seed() -> None:
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        if db.scalar(select(func.count()).select_from(Order)):
            return
        now = datetime.now(UTC)
        user_ids: list[int] = []
        for start in range(1, USER_COUNT + 1, BATCH_SIZE):
            users = [
                User(
                    name=f"User {index}",
                    email=f"user{index}@example.com",
                    created_at=now,
                )
                for index in range(start, min(start + BATCH_SIZE, USER_COUNT + 1))
            ]
            db.add_all(users)
            db.flush()
            user_ids.extend(user.id for user in users)

        for start in range(0, ORDER_COUNT, BATCH_SIZE):
            orders = [
                Order(
                    user_id=user_ids[index % USER_COUNT],
                    status=("CREATED", "PAID", "SHIPPED")[index % 3],
                    total_amount=1000 + (index % 50) * 100,
                    created_at=now - timedelta(minutes=index),
                )
                for index in range(start, min(start + BATCH_SIZE, ORDER_COUNT))
            ]
            db.add_all(orders)
            db.flush()
        db.commit()
    print(f"Seeded {USER_COUNT} users and {ORDER_COUNT} orders.")


if __name__ == "__main__":
    seed()
