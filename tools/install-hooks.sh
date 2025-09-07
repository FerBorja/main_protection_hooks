#!/usr/bin/env bash
set -euo pipefail
git config core.hooksPath .githooks
chmod +x .githooks/* || true
chmod +x tools/*.sh || true
echo "✅ hooks installed (core.hooksPath=.githooks)"
