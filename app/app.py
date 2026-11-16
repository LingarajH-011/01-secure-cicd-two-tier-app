"""Small Flask + MySQL notes service used for the secure CI/CD portfolio project."""
import os

import pymysql
from flask import Flask, jsonify, request


def get_conn():
    return pymysql.connect(
        host=os.getenv("DB_HOST", "db"),
        user=os.getenv("DB_USER", "appuser"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "appdb"),
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=3,
    )


def create_app(conn_factory=get_conn):
    app = Flask(__name__)

    @app.get("/health")
    def health():
        # Liveness: the process is up. Does not touch the database.
        return jsonify(status="ok")

    @app.get("/ready")
    def ready():
        # Readiness: the database is reachable.
        try:
            conn = conn_factory()
            conn.close()
            return jsonify(status="ready")
        except Exception:
            return jsonify(status="db-unavailable"), 503

    @app.get("/notes")
    def list_notes():
        conn = conn_factory()
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT id, text FROM notes ORDER BY id DESC LIMIT 50")
                rows = cur.fetchall()
            return jsonify(rows)
        finally:
            conn.close()

    @app.post("/notes")
    def add_note():
        payload = request.get_json(silent=True) or {}
        text = str(payload.get("text", "")).strip()
        if not text or len(text) > 255:
            return jsonify(error="text is required and must be 1-255 characters"), 400
        conn = conn_factory()
        try:
            with conn.cursor() as cur:
                # Parameterised query: protects against SQL injection.
                cur.execute("INSERT INTO notes (text) VALUES (%s)", (text,))
            conn.commit()
            return jsonify(status="created"), 201
        finally:
            conn.close()

    return app


app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
