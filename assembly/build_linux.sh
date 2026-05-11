#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ASM_DIR="$ROOT_DIR/assembly"

gcc -O2 -no-pie "$ASM_DIR/main_runnable_linux.S" -lm -o "$ASM_DIR/squares_sim"
echo "Built: $ASM_DIR/squares_sim"
