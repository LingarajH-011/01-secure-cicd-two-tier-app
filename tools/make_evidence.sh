#!/usr/bin/env bash
# Capture REAL command output as PNG images in screenshots/. Zero cost: local tools and sample data only.
#   bash tools/make_evidence.sh          (run from anywhere; needs: pip install pillow)
# Anything not installed is skipped. Only commit images you generated from real runs.
set -uo pipefail
cd "$(dirname "$0")/.."

PY="${PYTHON:-python3}"
NOTE="real output captured $(date -u +%Y-%m-%d) - local run, no AWS resources created"
have() { command -v "$1" >/dev/null 2>&1; }

# shot <png> <displayed command> <actual command...>
shot() {
  local png="$1" shown="$2"; shift 2
  mkdir -p screenshots
  ( "$@" 2>&1 ) | "$PY" tools/render_terminal.py "screenshots/$png" --cmd "$shown" --note "$NOTE" --width "${WIDTH:-110}" >/dev/null
  # Some tools exit non-zero when they find issues; that is expected, so just check the file exists.
  [ -s "screenshots/$png" ] && echo "  ok  screenshots/$png"
}

have flake8 && shot lint-and-tests.png "flake8 app && pytest app/tests -v" \
  bash -c "flake8 app --max-line-length=100 && echo 'flake8: no issues' && pytest app/tests -v -p no:cacheprovider"
if have docker && docker ps --format '{{.Names}}' 2>/dev/null | grep -q .; then
  shot docker-ps.png "docker ps" docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
fi
echo "Tip: also screenshot the green GitHub Actions run and the Trivy report by hand."
