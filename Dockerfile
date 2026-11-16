FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create an unprivileged user: the container never runs as root.
RUN groupadd --system --gid 999 app && useradd --system --uid 999 --gid app --no-create-home app

WORKDIR /srv
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

USER app
EXPOSE 5000

# Health check using only the standard library (no curl needed in the image).
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=2).status==200 else 1)"

# --worker-tmp-dir /dev/shm lets gunicorn run with a read-only root filesystem.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--worker-tmp-dir", "/dev/shm", "app:app"]
