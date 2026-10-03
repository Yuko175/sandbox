import logging
from collections.abc import Generator
from contextvars import ContextVar
from pathlib import Path

from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker

DATABASE_PATH = Path(__file__).resolve().parents[3] / "data" / "order.db"
DATABASE_URL = f"sqlite:///{DATABASE_PATH}"

DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
query_count: ContextVar[int] = ContextVar("query_count", default=0)
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
    echo=False,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


@event.listens_for(engine, "before_cursor_execute")
def log_sql(
    _connection,
    _cursor,
    statement,
    parameters,
    _context,
    _executemany,
) -> None:
    current_count = query_count.get() + 1
    query_count.set(current_count)
    logging.getLogger("order_service.sql").info(
        "SQL #%d: %s | parameters=%s",
        current_count,
        statement.replace("\n", " "),
        parameters,
    )


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
