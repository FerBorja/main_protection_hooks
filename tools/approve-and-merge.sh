#!/usr/bin/env bash
set -euo pipefail

REQUIRED_APPROVALS="${REQUIRED_APPROVALS:-1}"
ALLOWLIST_FILE="approvers/ALLOWLIST.txt"
MAIN_BRANCH="main"

usage() {
  echo "Usage: $0 <source-branch>"
  exit 1
}

[[ $# -eq 1 ]] || usage
SRC="$1"

TARGET_SHA="$(git rev-parse "$SRC")" || { echo "Branch $SRC not found"; exit 1; }

git rev-parse "$MAIN_BRANCH" >/dev/null 2>&1 || { echo "No '$MAIN_BRANCH' branch."; exit 1; }

[[ "$(git rev-parse --abbrev-ref HEAD)" != "$MAIN_BRANCH" ]] || { echo "Don't run on '$MAIN_BRANCH'."; exit 1; }

# Ensure main is ancestor of SRC (SRC up-to-date with main)
if ! git merge-base --is-ancestor "$MAIN_BRANCH" "$SRC"; then
  echo "⚠ '$SRC' is behind '$MAIN_BRANCH'. Rebase or merge '$MAIN_BRANCH' into '$SRC' first."
  exit 1
fi

mapfile -t tags < <(git tag -l "approve/${TARGET_SHA}/*")
if [[ ${#tags[@]} -eq 0 ]]; then
  echo "❌ No approval tags found for $TARGET_SHA"
  echo "   Have an approver run: tools/make-approval-tag.sh $SRC"
  exit 1
fi

[[ -f "$ALLOWLIST_FILE" ]] || { echo "Allow-list $ALLOWLIST_FILE missing"; exit 1; }

OK_COUNT=0
echo "🔍 Checking approvals for $TARGET_SHA"
while IFS= read -r allowed_email; do
  [[ -z "$allowed_email" || "$allowed_email" =~ ^\s*# ]] && continue
  for t in "${tags[@]}"; do
    if [[ "$t" == "approve/${TARGET_SHA}/${allowed_email}" ]]; then
      if git verify-tag "$t" >/dev/null 2>&1; then
        echo "  ✅ valid signature from $allowed_email on $t"
        OK_COUNT=$((OK_COUNT+1))
      else
        echo "  ❌ tag $t exists but signature is invalid"
      fi
    fi
  done
done < "$ALLOWLIST_FILE"

if (( OK_COUNT < REQUIRED_APPROVALS )); then
  echo "❌ Need at least $REQUIRED_APPROVALS approval(s); got $OK_COUNT"
  exit 1
fi

echo "✅ Approvals satisfied. Merging '$SRC' into '$MAIN_BRANCH'..."
git checkout "$MAIN_BRANCH"
git merge --ff-only "$TARGET_SHA"

echo "🎉 '$MAIN_BRANCH' updated to include $TARGET_SHA"
