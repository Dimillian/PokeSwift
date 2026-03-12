#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT/.build/DerivedData"
LOG_DIR="$ROOT/.build/logs"
XCBEAUTIFY_BIN="${XCBEAUTIFY_BIN:-$(command -v xcbeautify || true)}"
XCBUILD_STATE_DIR="$DERIVED_DATA/Build/Intermediates.noindex/XCBuildData"

timestamp() {
  date '+%H:%M:%S'
}

section() {
  printf '\n[%s] %s\n' "$(timestamp)" "$1"
}

detail() {
  printf '  - %s\n' "$1"
}

reset_xcode_incremental_state() {
  if [[ -d "$XCBUILD_STATE_DIR" ]]; then
    detail "Resetting cached Xcode task metadata"
    rm -rf "$XCBUILD_STATE_DIR"
  fi
}

run_xcodebuild() {
  local scheme="$1"
  local log_file="$LOG_DIR/${scheme}.log"

  section "Build scheme: $scheme"
  detail "Writing raw build log to $log_file"

  if [[ -n "$XCBEAUTIFY_BIN" ]]; then
    xcodebuild \
      -workspace PokeSwift.xcworkspace \
      -scheme "$scheme" \
      -configuration Debug \
      -derivedDataPath "$DERIVED_DATA" \
      build 2>&1 | tee "$log_file" | "$XCBEAUTIFY_BIN" --disable-logging
  else
    detail "xcbeautify not found; falling back to raw xcodebuild output"
    xcodebuild \
      -workspace PokeSwift.xcworkspace \
      -scheme "$scheme" \
      -configuration Debug \
      -derivedDataPath "$DERIVED_DATA" \
      build 2>&1 | tee "$log_file"
  fi
}

trap 'printf "\n[%s] Build pipeline failed.\n" "$(timestamp)" >&2' ERR

cd "$ROOT"
mkdir -p "$LOG_DIR"

section "PokeSwift build pipeline"
detail "Repo root: $ROOT"
detail "Derived data: $DERIVED_DATA"
detail "Build logs: $LOG_DIR"

section "Generate workspace"
tuist generate --no-open
reset_xcode_incremental_state

run_xcodebuild "PokeExtractCLI"
run_xcodebuild "PokeMac"

section "Build pipeline complete"
detail "Built schemes: PokeExtractCLI, PokeMac"
