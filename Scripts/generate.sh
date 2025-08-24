#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

cd "${REPO_ROOT}"

echo "[tuist] Generating project..."
tuist generate || {
  echo "[tuist] generate failed" >&2
  exit 1
}

echo "[tuist] Done. Open with: open Vibeviewer.xcworkspace"


