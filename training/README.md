# セットアップ

Python 3.12以上と [uv](https://docs.astral.sh/uv/) を使用します。

```bash
uv sync
uv run python scripts/seed.py
uv run uvicorn order_service.main:app --reload
```

Order Serviceの起動前に、別ターミナルで配送API Mockを起動します。

```bash
uv run python scripts/mock_delivery_api.py
```

Mockは `http://127.0.0.1:9000` で起動し、次のリクエストを受け付けます。

```text
GET /delivery-status/{order_id}
```

確認例:

```bash
curl http://127.0.0.1:9000/delivery-status/1
# {"order_id":1,"status":"delivered"}
```

その後、Order Serviceを別ターミナルで起動します。

```bash
uv run uvicorn order_service.main:app --reload
```

Order Serviceは `http://127.0.0.1:8000/orders` で利用できます。

```bash
curl http://127.0.0.1:8000/orders
```

配送APIの接続先を変更する場合は、`DELIVERY_API_BASE_URL` を設定します。

## 開発環境

- Python
- FastAPI
- SQLAlchemy
- SQLite
- pytest
- uv
- VS Code

詳細な要件・設計は `docs/` 配下を参照してください。
