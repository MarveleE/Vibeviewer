#!/bin/zsh
set -euo pipefail

echo "[clean] Cleaning Xcode DerivedData for current project only..."

# Project name prefix inferred from repo root folder
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)
PROJECT_PREFIX=$(basename "$REPO_ROOT")

# Xcode DerivedData (current user)
DERIVED_DATA_DIR=~/Library/Developer/Xcode/DerivedData

if [ -d "$DERIVED_DATA_DIR" ]; then
  # In zsh, enable null_glob so non-matching globs expand to empty
  setopt null_glob 2>/dev/null || true
  matches=("$DERIVED_DATA_DIR"/${PROJECT_PREFIX}-*)
  if [ ${#matches[@]} -gt 0 ]; then
    echo "[clean] Removing:"
    for p in "${matches[@]}"; do
      echo "  - $p"
    done
    rm -rf "${matches[@]}"
  else
    echo "[clean] No DerivedData entries found for prefix: ${PROJECT_PREFIX}-*"
  fi
else
  echo "[clean] Not found: $DERIVED_DATA_DIR"
fi

# Clean Tuist caches for current project only
# We pass --path to ensure tuist cleans caches scoped to this project
if command -v tuist >/dev/null 2>&1; then
  echo "[clean] Cleaning Tuist caches for this project..."
  tuist clean --path "$REPO_ROOT" || true
else
  echo "[clean] tuist not found, skipping tuist cache clean"
fi

echo "[clean] Done."


