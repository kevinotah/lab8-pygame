#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ASM_DIR="$ROOT_DIR/assembly"

if [[ ! -x "$ASM_DIR/squares_sim" ]]; then
  echo "Binary not found. Building first..."
  bash "$ASM_DIR/build_linux.sh"
fi

"$ASM_DIR/squares_sim"
