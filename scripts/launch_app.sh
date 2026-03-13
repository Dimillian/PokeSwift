#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT/.build/DerivedData"
PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Debug"
EXTRACTOR="$PRODUCTS_DIR/PokeExtractCLI"
APP_BUNDLE="$PRODUCTS_DIR/PokeMac.app"
CONTENT_ROOT="$ROOT/Content"
CONTENT_VARIANT_ROOT="$CONTENT_ROOT/Red"
CONTENT_MANIFEST="$CONTENT_VARIANT_ROOT/game_manifest.json"
TRACE_ROOT="${POKESWIFT_TRACE_DIR:-$HOME/Library/Caches/PokeSwift/Traces/pokemac}"
SAVE_ROOT="${POKESWIFT_SAVE_ROOT:-$HOME/Library/Application Support/PokeSwift/Saves}"
TELEMETRY_PORT="${POKESWIFT_TELEMETRY_PORT:-9777}"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/PokeMac"
WATCHER_HELPER="$ROOT/scripts/watch_live_session.py"
WATCHER_REQUIREMENTS="$ROOT/scripts/watch_live_session_requirements.txt"
WATCH_MODE="${POKESWIFT_WATCH_MODE:-auto}"
WATCHER_VENV_DIR="${POKESWIFT_WATCHER_VENV_DIR:-$ROOT/.build/live-watch-venv}"
WATCHER_PYTHON="$WATCHER_VENV_DIR/bin/python3"
READINESS_TIMEOUT_SECONDS=15
APP_PID=0
APP_EXIT_STATUS=0
SUPERVISED_LAUNCH=0
CLEANUP_COMPLETE=0
TELEMETRY_TRACE_FILE="$TRACE_ROOT/telemetry.jsonl"
SESSION_TRACE_FILE="$TRACE_ROOT/session_events.jsonl"
TELEMETRY_TRACE_SIZE_BEFORE=0
SESSION_TRACE_SIZE_BEFORE=0

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

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '[%s] Missing required command: %s\n' "$(timestamp)" "$command_name" >&2
    exit 1
  fi
}

ensure_live_watch_runtime() {
  require_command "python3"
  require_command "curl"
  if [[ ! -f "$WATCHER_HELPER" ]]; then
    printf '[%s] Missing live watcher helper at %s\n' "$(timestamp)" "$WATCHER_HELPER" >&2
    exit 1
  fi
  if [[ ! -f "$WATCHER_REQUIREMENTS" ]]; then
    printf '[%s] Missing live watcher requirements at %s\n' "$(timestamp)" "$WATCHER_REQUIREMENTS" >&2
    exit 1
  fi

  if [[ ! -x "$WATCHER_PYTHON" ]]; then
    detail "Creating live-watch Python environment"
    python3 -m venv "$WATCHER_VENV_DIR"
  fi

  if ! "$WATCHER_PYTHON" -c 'import rich' >/dev/null 2>&1; then
    detail "Installing live-watch terminal UI dependencies"
    "$WATCHER_PYTHON" -m pip install --disable-pip-version-check --quiet -r "$WATCHER_REQUIREMENTS"
  fi
}

manifest_source_commit() {
  sed -n 's/.*"sourceCommit" : "\(.*\)",/\1/p' "$CONTENT_MANIFEST" | head -n 1
}

should_refresh_content() {
  if [[ ! -f "$CONTENT_MANIFEST" ]]; then
    return 0
  fi

  local source_commit
  source_commit="$(manifest_source_commit)"
  if [[ -z "$source_commit" ]]; then
    return 0
  fi

  if ! git rev-parse -q --verify "${source_commit}^{commit}" >/dev/null 2>&1; then
    return 0
  fi

  local -a source_paths
  source_paths=("${(@f)$(sed -n 's/.*"path" : "\(.*\)",/\1/p' "$CONTENT_MANIFEST")}")
  if (( ${#source_paths[@]} == 0 )); then
    return 0
  fi

  if ! git diff --quiet "${source_commit}..HEAD" -- "${source_paths[@]}"; then
    return 0
  fi

  if ! git diff --quiet -- "${source_paths[@]}"; then
    return 0
  fi

  if ! git diff --cached --quiet -- "${source_paths[@]}"; then
    return 0
  fi

  return 1
}

watch_mode_enabled() {
  case "$WATCH_MODE" in
    1)
      return 0
      ;;
    0)
      return 1
      ;;
    auto|'')
      [[ -t 1 ]]
      return $?
      ;;
    *)
      printf '[%s] Invalid POKESWIFT_WATCH_MODE value: %s\n' "$(timestamp)" "$WATCH_MODE" >&2
      exit 1
      ;;
  esac
}

process_running() {
  local pid="$1"
  local state
  if [[ -z "$pid" || "$pid" == "0" ]]; then
    return 1
  fi
  state="$(ps -o state= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
  if [[ -n "$state" ]]; then
    [[ "$state" != Z* ]]
    return $?
  fi
  kill -0 "$pid" >/dev/null 2>&1
}

file_size_or_zero() {
  local path="$1"
  if [[ -f "$path" ]]; then
    stat -f '%z' "$path" 2>/dev/null || printf '0'
  else
    printf '0'
  fi
}

record_trace_sizes() {
  TELEMETRY_TRACE_SIZE_BEFORE="$(file_size_or_zero "$TELEMETRY_TRACE_FILE")"
  SESSION_TRACE_SIZE_BEFORE="$(file_size_or_zero "$SESSION_TRACE_FILE")"
}

trace_activity_detected() {
  local telemetry_trace_size
  local session_trace_size

  telemetry_trace_size="$(file_size_or_zero "$TELEMETRY_TRACE_FILE")"
  session_trace_size="$(file_size_or_zero "$SESSION_TRACE_FILE")"

  if (( telemetry_trace_size > TELEMETRY_TRACE_SIZE_BEFORE )); then
    return 0
  fi
  if (( session_trace_size > SESSION_TRACE_SIZE_BEFORE )); then
    return 0
  fi
  return 1
}

telemetry_healthcheck() {
  curl -fsS --max-time 1 "http://127.0.0.1:${TELEMETRY_PORT}/health" >/dev/null 2>&1
}

wait_for_runtime_ready() {
  local deadline=$(( SECONDS + READINESS_TIMEOUT_SECONDS ))

  while (( SECONDS < deadline )); do
    if ! process_running "$APP_PID"; then
      return 1
    fi

    if telemetry_healthcheck || trace_activity_detected; then
      return 0
    fi

    sleep 0.25
  done

  return 1
}

post_quit_request() {
  curl -fsS --max-time 1 -X POST "http://127.0.0.1:${TELEMETRY_PORT}/quit" >/dev/null 2>&1
}

stop_supervised_app() {
  if (( APP_PID == 0 )); then
    return 0
  fi

  if process_running "$APP_PID"; then
    post_quit_request || true

    local deadline=$(( SECONDS + 2 ))
    while (( SECONDS < deadline )); do
      if ! process_running "$APP_PID"; then
        break
      fi
      sleep 0.1
    done

    if process_running "$APP_PID"; then
      kill "$APP_PID" >/dev/null 2>&1 || true
    fi
  fi

  if (( APP_PID != 0 )); then
    set +e
    wait "$APP_PID"
    APP_EXIT_STATUS=$?
    set -e
    APP_PID=0
  fi
}

cleanup_on_exit() {
  local exit_code="$1"

  if (( SUPERVISED_LAUNCH == 1 && CLEANUP_COMPLETE == 0 )); then
    CLEANUP_COMPLETE=1
    stop_supervised_app
  fi

  return "$exit_code"
}

trap 'printf "\n[%s] Launch pipeline failed.\n" "$(timestamp)" >&2' ERR
trap 'cleanup_on_exit $?' EXIT
trap 'exit 130' INT TERM

cd "$ROOT"

section "PokeSwift launch pipeline"
detail "Repo root: $ROOT"
detail "Derived data: $DERIVED_DATA"
detail "App bundle: $APP_BUNDLE"
detail "App executable: $APP_EXECUTABLE"
detail "Content root: $CONTENT_VARIANT_ROOT"
detail "Trace root: $TRACE_ROOT"
detail "Save root: $SAVE_ROOT"
detail "Telemetry port: $TELEMETRY_PORT"
detail "Watch mode: $WATCH_MODE"

section "1/4 Generate workspace and build debug targets"
detail "Building schemes: PokeExtractCLI, PokeMac"
./scripts/build_app.sh

require_executable "$EXTRACTOR" "PokeExtractCLI"
if [[ ! -d "$APP_BUNDLE" ]]; then
  printf '[%s] Missing PokeMac.app at %s\n' "$(timestamp)" "$APP_BUNDLE" >&2
  exit 1
fi
require_executable "$APP_EXECUTABLE" "PokeMac executable"

WATCH_MODE_ACTIVE=0
if watch_mode_enabled; then
  WATCH_MODE_ACTIVE=1
  ensure_live_watch_runtime
fi

section "2/4 Extract Red content"
if should_refresh_content; then
  detail "Refreshing extracted runtime assets under $CONTENT_VARIANT_ROOT"
  "$EXTRACTOR" extract --game red --repo-root "$ROOT" --output-root "$CONTENT_ROOT"
else
  detail "Skipping extract; tracked content source inputs are unchanged"
fi

section "3/4 Verify extracted Red content"
detail "Checking extracted manifests and asset availability"
"$EXTRACTOR" verify --game red --repo-root "$ROOT" --output-root "$CONTENT_ROOT"

section "4/4 Launch macOS app"
detail "Launching PokeMac executable with explicit runtime roots"
record_trace_sizes
POKESWIFT_CONTENT_ROOT="$CONTENT_ROOT" \
POKESWIFT_TRACE_DIR="$TRACE_ROOT" \
POKESWIFT_SAVE_ROOT="$SAVE_ROOT" \
POKESWIFT_TELEMETRY_PORT="$TELEMETRY_PORT" \
"$APP_EXECUTABLE" >/dev/null 2>&1 &
APP_PID=$!

section "Launch request sent"
detail "App bundle: $APP_BUNDLE"
detail "App PID: $APP_PID"

if (( WATCH_MODE_ACTIVE == 0 )); then
  exit 0
fi

SUPERVISED_LAUNCH=1
detail "Waiting for telemetry server or fresh trace activity"
if ! wait_for_runtime_ready; then
  if process_running "$APP_PID"; then
    printf '[%s] App did not expose telemetry or fresh trace activity within %ss\n' "$(timestamp)" "$READINESS_TIMEOUT_SECONDS" >&2
  else
    set +e
    wait "$APP_PID"
    APP_EXIT_STATUS=$?
    set -e
    APP_PID=0
    printf '[%s] App exited before telemetry or trace activity was ready (status %s)\n' "$(timestamp)" "$APP_EXIT_STATUS" >&2
  fi
  exit 1
fi

section "Live watch attached"
detail "Press Ctrl-C to stop the watcher and quit PokeMac"
set +e
"$WATCHER_PYTHON" "$WATCHER_HELPER" \
  --port "$TELEMETRY_PORT" \
  --trace-root "$TRACE_ROOT" \
  --save-root "$SAVE_ROOT" \
  --app-pid "$APP_PID"
WATCHER_STATUS=$?
set -e

if (( WATCHER_STATUS == 130 )); then
  exit 130
fi

if process_running "$APP_PID"; then
  printf '[%s] Live watcher ended unexpectedly while PokeMac is still running.\n' "$(timestamp)" >&2
  exit 1
fi

set +e
wait "$APP_PID"
APP_EXIT_STATUS=$?
set -e
APP_PID=0
SUPERVISED_LAUNCH=0

section "PokeMac terminated"
detail "Exit status: $APP_EXIT_STATUS"
exit "$APP_EXIT_STATUS"
