#!/usr/bin/env bash
# Roll back to the previous successfully deployed commit (or a commit you pass in).
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  [ -f .deploy-history ] || { echo "No deploy history"; exit 1; }
  TARGET=$(tail -n 2 .deploy-history | head -n 1)
fi

echo "Rolling back to $TARGET"
git checkout "$TARGET" -- app Dockerfile docker-compose.yml
docker compose build
docker compose up -d
curl -fsS http://127.0.0.1:5000/ready && echo "Rollback OK"
echo "Remember: run 'git checkout HEAD -- .' to restore your working tree afterwards."
