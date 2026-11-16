#!/usr/bin/env bash
# Fill in the author line of the root README.
#   bash tools/set_profile.sh "Your Name" "https://www.linkedin.com/in/your-id" ["you@example.com"]
# The email is optional: a public repo makes it visible to everyone, so only add one you are happy to publish.
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="${1:?usage: set_profile.sh NAME LINKEDIN_URL [EMAIL]}"
LINKEDIN="${2:?usage: set_profile.sh NAME LINKEDIN_URL [EMAIL]}"
EMAIL="${3:-}"

LINE="> **Author:** ${NAME} · **LinkedIn:** [${LINKEDIN}](${LINKEDIN})"
[ -n "$EMAIL" ] && LINE="${LINE} · **Contact:** ${EMAIL}"

python3 - "$LINE" <<'EOF'
import re, sys
path = "README.md"
text = open(path, encoding="utf-8").read()
new, n = re.subn(r"^> \*\*Author:\*\*.*$", lambda m: sys.argv[1], text, count=1, flags=re.M)
if n == 0:
    sys.exit("Author line not found in README.md")
open(path, "w", encoding="utf-8").write(new)
print("Updated:", sys.argv[1])
EOF
