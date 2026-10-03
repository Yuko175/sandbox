import random
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select

from order_service.database import SessionLocal, engine
from order_service.model import Base, Order

ORDER_COUNT = 100
RANDOM_SEED = 42
UPDATE_AT_BASE = datetime(2026, 1, 1, tzinfo=UTC)
COMPANY_NAMES = [
    "A株式会社",
    "B有限会社",
    "C合同会社",
    "D商店",
    "E Inc.",
]


def seed() -> None:
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        if db.scalar(select(func.count()).select_from(Order)):
            return
        random_generator = random.Random(RANDOM_SEED)
        db.add_all(
            [
                Order(
                    id=order_id,
                    customer_name=(
                        f"{COMPANY_NAMES[(order_id - 1) % len(COMPANY_NAMES)]} "
                        f"{(order_id - 1) // len(COMPANY_NAMES) + 1:03d}"
                    ),
                    update_at=UPDATE_AT_BASE
                    + timedelta(
                        days=random_generator.randint(0, 365),
                        hours=random_generator.randint(0, 23),
                        minutes=random_generator.randint(0, 59),
                        seconds=random_generator.randint(0, 59),
                        milliseconds=random_generator.randint(0, 999),
                        microseconds=random_generator.randint(0, 999),
                    ),
                )
                for order_id in range(1, ORDER_COUNT + 1)
            ]
        )
        db.commit()
    print(f"Seeded {ORDER_COUNT} orders.")


if __name__ == "__main__":
    seed()
