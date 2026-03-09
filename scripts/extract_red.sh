#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/build_app.sh
.build/DerivedData/Build/Products/Debug/PokeExtractCLI extract --game red --repo-root "$ROOT" --output-root "$ROOT/Content"
.build/DerivedData/Build/Products/Debug/PokeExtractCLI verify --game red --repo-root "$ROOT" --output-root "$ROOT/Content"
