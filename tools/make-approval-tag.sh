#!/usr/bin/env bash
set -euo pipefail
branch="${1:-}"
if [[ -z "$branch" ]]; then
  echo "Usage: $0 <branch>"
  exit 1
fi
sha="$(git rev-parse "$branch")"
email="$(git config user.email)"
if [[ -z "$email" ]]; then
  echo "No git user.email set; run: git config user.email you@example.com"
  exit 1
fi
git tag -s "approve/${sha}/${email}" -m "Approve ${sha}" "${sha}"
echo "✅ Created signed approval tag: approve/${sha}/${email}"
