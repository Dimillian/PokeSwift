#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT/.build/DerivedData"
PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Debug"
EXTRACTOR="$PRODUCTS_DIR/PokeExtractCLI"
HARNESS="$PRODUCTS_DIR/PokeHarness"
APP_BUNDLE="$PRODUCTS_DIR/PokeMac.app"
CONTENT_ROOT="$ROOT/Content"
TRACE_DIR="$ROOT/.runtime-traces/pokemac"

timestamp() {
  date '+%H:%M:%S'
}

section() {
  printf '\n[%s] %s\n' "$(timestamp)" "$1"
}

detail() {
  printf '  - %s\n' "$1"
}

require_executable() {
  local path="$1"
  local label="$2"
  if [[ ! -x "$path" ]]; then
    printf '[%s] Missing %s at %s\n' "$(timestamp)" "$label" "$path" >&2
    exit 1
  fi
}

trap 'printf "\n[%s] Launch pipeline failed.\n" "$(timestamp)" >&2' ERR

cd "$ROOT"

section "PokeSwift launch pipeline"
detail "Repo root: $ROOT"
detail "Derived data: $DERIVED_DATA"
detail "App bundle: $APP_BUNDLE"
detail "Content root: $CONTENT_ROOT/Red"
detail "Trace directory: $TRACE_DIR"

section "1/4 Generate workspace and build debug targets"
detail "Building schemes: PokeExtractCLI, PokeHarness, PokeMac"
./scripts/build_app.sh

require_executable "$EXTRACTOR" "PokeExtractCLI"
require_executable "$HARNESS" "PokeHarness"

section "2/4 Extract Red content"
detail "Refreshing extracted runtime assets under $CONTENT_ROOT/Red"
"$EXTRACTOR" extract --game red --repo-root "$ROOT" --output-root "$CONTENT_ROOT"

section "3/4 Verify extracted Red content"
detail "Checking extracted manifests and asset availability"
"$EXTRACTOR" verify --game red --repo-root "$ROOT" --output-root "$CONTENT_ROOT"

section "4/4 Launch macOS app"
detail "Launching via PokeHarness so telemetry/input automation remains available"
"$HARNESS" launch

section "Launch request sent"
detail "App logs: $TRACE_DIR/app.log"
detail "Telemetry trace: $TRACE_DIR/telemetry.jsonl"
detail "Session event trace: $TRACE_DIR/session_events.jsonl"
