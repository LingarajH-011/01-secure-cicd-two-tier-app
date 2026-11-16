import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from app import create_app  # noqa: E402


class FakeCursor:
    def __init__(self, store):
        self.store = store
        self._rows = []

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def execute(self, sql, params=None):
        if sql.startswith("INSERT"):
            self.store.append({"id": len(self.store) + 1, "text": params[0]})
        elif sql.startswith("SELECT"):
            self._rows = list(reversed(self.store))

    def fetchall(self):
        return self._rows


class FakeConn:
    def __init__(self, store):
        self.store = store

    def cursor(self):
        return FakeCursor(self.store)

    def commit(self):
        pass

    def close(self):
        pass


def make_client(store=None, fail=False):
    store = store if store is not None else []

    def factory():
        if fail:
            raise RuntimeError("db down")
        return FakeConn(store)

    return create_app(factory).test_client()


def test_health():
    r = make_client().get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_ready_ok():
    assert make_client().get("/ready").status_code == 200


def test_ready_db_down():
    assert make_client(fail=True).get("/ready").status_code == 503


def test_add_and_list_notes():
    c = make_client()
    assert c.post("/notes", json={"text": "hello"}).status_code == 201
    r = c.get("/notes")
    assert r.status_code == 200
    assert r.get_json()[0]["text"] == "hello"


def test_rejects_empty_note():
    assert make_client().post("/notes", json={"text": "  "}).status_code == 400


def test_rejects_long_note():
    assert make_client().post("/notes", json={"text": "x" * 256}).status_code == 400
