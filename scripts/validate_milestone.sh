#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/extract_red.sh
.build/DerivedData/Build/Products/Debug/PokeHarness validate
