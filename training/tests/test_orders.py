from datetime import datetime

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from order_service.database import get_db
from order_service.main import app
from order_service.model import Base, Order, User


def test_list_orders_returns_order_and_user_data():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    with session_factory() as db:
        user = User(name="Alice", email="alice@example.com", created_at=datetime.now())
        db.add(user)
        db.flush()
        db.add(
            Order(
                user_id=user.id,
                status="CREATED",
                total_amount=5000,
                created_at=datetime.now(),
            )
        )
        db.commit()

    def override_get_db():
        with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    try:
        response = TestClient(app).get("/orders")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()[0]["userName"] == "Alice"
    assert response.json()[0]["totalAmount"] == 5000


def test_list_orders_returns_all_orders():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    with session_factory() as db:
        user = User(name="Alice", email="alice@example.com", created_at=datetime.now())
        db.add(user)
        db.flush()
        db.add_all(
            [
                Order(
                    user_id=user.id,
                    status="CREATED",
                    total_amount=index,
                    created_at=datetime.now(),
                )
                for index in range(3)
            ]
        )
        db.commit()

    def override_get_db():
        with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    try:
        response = TestClient(app).get("/orders")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert len(response.json()) == 3
