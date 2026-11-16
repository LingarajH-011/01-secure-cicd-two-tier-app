#!/usr/bin/env bash
# Deploy the current git commit with Docker Compose and record it for rollback.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "Missing .env (copy .env.example)"; exit 1; }

REV=$(git rev-parse --short HEAD)
echo "Deploying $REV"
docker compose build --pull
docker compose up -d

# Wait for the app to report healthy.
for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    echo "$REV" >> .deploy-history
    echo "Deploy OK: $REV"
    exit 0
  fi
  sleep 2
done

echo "Health check failed. Roll back with scripts/rollback.sh"
exit 1
