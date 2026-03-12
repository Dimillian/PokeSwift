#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request
from collections import deque
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Watch PokeSwift live telemetry and session events.")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--trace-root", required=True)
    parser.add_argument("--save-root", required=True)
    parser.add_argument("--app-pid", type=int, required=True)
    parser.add_argument("--poll-interval", type=float, default=0.25)
    return parser.parse_args()


def process_running(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        result = subprocess.run(
            ["ps", "-o", "state=", "-p", str(pid)],
            capture_output=True,
            check=False,
            text=True,
        )
        state = result.stdout.strip()
        if state:
            return state.startswith("Z") is False
    except OSError:
        pass
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    return True


def iso_time(timestamp: str | None) -> str:
    if not timestamp:
        return "--:--:--"
    if "T" in timestamp and len(timestamp) >= 19:
        return timestamp[11:19]
    return timestamp[-8:]


def truncate(text: str, width: int) -> str:
    if width <= 0:
        return ""
    if len(text) <= width:
        return text
    if width <= 3:
        return text[:width]
    return text[: width - 3] + "..."


def format_position(position: object) -> str:
    if not isinstance(position, dict):
        return "--,--"
    return f"{position.get('x', '--')},{position.get('y', '--')}"


def compact_text(lines: object) -> str:
    if not isinstance(lines, list):
        return ""
    return " / ".join(str(line).strip() for line in lines if str(line).strip())


class LiveSessionWatcher:
    def __init__(self, args: argparse.Namespace) -> None:
        self.port = args.port
        self.trace_root = Path(args.trace_root)
        self.save_root = Path(args.save_root)
        self.app_pid = args.app_pid
        self.poll_interval = max(0.1, args.poll_interval)
        self.session_event_path = self.trace_root / "session_events.jsonl"
        self.snapshot_url = f"http://127.0.0.1:{self.port}/telemetry/latest"
        self.events: deque[dict[str, object]] = deque(maxlen=12)
        self.snapshot: dict[str, object] | None = None
        self.last_snapshot_error = "waiting for telemetry"
        self.last_snapshot_success_at: float | None = None
        self.next_snapshot_poll_at = 0.0
        self.stop_requested = False
        self.tty = sys.stdout.isatty()
        self._session_handle = None
        self._plain_last_summary = ""
        self._plain_last_status_at = 0.0
        self._cursor_hidden = False
        signal.signal(signal.SIGTERM, self._request_stop)
        signal.signal(signal.SIGINT, self._request_stop)

    def _request_stop(self, _signum: int, _frame: object) -> None:
        self.stop_requested = True

    def run(self) -> int:
        try:
            self._enter_screen()
            while self.stop_requested is False:
                now = time.monotonic()
                self._poll_snapshot(now)
                self._poll_events()
                if self.tty:
                    self._render_dashboard()
                else:
                    self._emit_plain_status(now)

                if process_running(self.app_pid) is False:
                    return 0

                time.sleep(self.poll_interval)
            return 130
        finally:
            self._leave_screen()
            self._close_event_file()

    def _enter_screen(self) -> None:
        if self.tty is False:
            return
        sys.stdout.write("\x1b[?25l")
        sys.stdout.flush()
        self._cursor_hidden = True

    def _leave_screen(self) -> None:
        if self.tty and self._cursor_hidden:
            sys.stdout.write("\x1b[?25h\x1b[0m\n")
            sys.stdout.flush()
            self._cursor_hidden = False

    def _close_event_file(self) -> None:
        if self._session_handle is not None:
            self._session_handle.close()
            self._session_handle = None

    def _poll_snapshot(self, now: float) -> None:
        if now < self.next_snapshot_poll_at:
            return

        retry_delay = self.poll_interval if self.last_snapshot_success_at is not None else 2.0
        try:
            request = urllib.request.Request(self.snapshot_url, headers={"Accept": "application/json"})
            with urllib.request.urlopen(request, timeout=0.5) as response:
                payload = json.load(response)
            if isinstance(payload, dict) is False:
                raise ValueError("snapshot payload is not an object")
            self.snapshot = payload
            self.last_snapshot_error = ""
            self.last_snapshot_success_at = now
            self.next_snapshot_poll_at = now + self.poll_interval
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError, json.JSONDecodeError) as error:
            self.snapshot = None
            self.last_snapshot_error = str(error)
            self.next_snapshot_poll_at = now + retry_delay

    def _poll_events(self) -> None:
        if self._session_handle is None:
            if self.session_event_path.exists() is False:
                return
            self._session_handle = self.session_event_path.open("r", encoding="utf-8")
            self._session_handle.seek(0, os.SEEK_END)
            return

        if self.session_event_path.exists() is False:
            self._close_event_file()
            return

        current_offset = self._session_handle.tell()
        current_size = self.session_event_path.stat().st_size
        if current_size < current_offset:
            self._close_event_file()
            return

        while True:
            line = self._session_handle.readline()
            if not line:
                break
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(event, dict) is False:
                continue
            self.events.append(event)
            if self.tty is False:
                print(self._format_event_line(event), flush=True)

    def _status_value(self, key: str, default: str = "--") -> str:
        if self.snapshot is None:
            return default
        value = self.snapshot.get(key)
        if value in (None, ""):
            return default
        return str(value)

    def _telemetry_state(self) -> str:
        if self.snapshot is not None:
            return "live"
        if self.last_snapshot_success_at is None:
            return f"waiting (file-only): {self.last_snapshot_error}"
        return f"snapshot unavailable: {self.last_snapshot_error}"

    def _current_panel_lines(self, width: int) -> list[str]:
        snapshot = self.snapshot or {}
        battle = snapshot.get("battle")
        dialogue = snapshot.get("dialogue")
        shop = snapshot.get("shop")
        healing = snapshot.get("fieldHealing")
        prompt = snapshot.get("fieldPrompt")
        field = snapshot.get("field")

        lines: list[str] = []
        if isinstance(battle, dict):
            trainer = battle.get("trainerName") or battle.get("battleID") or "battle"
            text = compact_text(battle.get("textLines"))
            lines.append(f"Battle: {battle.get('kind', '--')} vs {trainer} | phase {battle.get('phase', '--')}")
            lines.append(text or "Battle text: --")
        elif isinstance(dialogue, dict):
            lines.append(
                f"Dialogue: {dialogue.get('dialogueID', '--')} | page "
                f"{int(dialogue.get('pageIndex', 0)) + 1}/{dialogue.get('pageCount', '--')}"
            )
            lines.append(compact_text(dialogue.get("lines")) or "Dialogue text: --")
        elif isinstance(shop, dict):
            lines.append(f"Shop: {shop.get('title', '--')} | phase {shop.get('phase', '--')}")
            lines.append(shop.get("promptText") or "Prompt: --")
        elif isinstance(healing, dict):
            lines.append(
                f"Healing: phase {healing.get('phase', '--')} | "
                f"balls {healing.get('activeBallCount', '--')}/{healing.get('totalBallCount', '--')}"
            )
            lines.append(f"Nurse: {healing.get('nurseObjectID', '--')}")
        elif isinstance(prompt, dict):
            options = prompt.get("options") if isinstance(prompt.get("options"), list) else []
            lines.append(f"Field prompt: {prompt.get('kind', '--')} | focus {prompt.get('focusedIndex', '--')}")
            lines.append(f"Options: {', '.join(str(option) for option in options) if options else '--'}")
        elif isinstance(field, dict):
            transition = field.get("transition") if isinstance(field.get("transition"), dict) else None
            alert = field.get("alert") if isinstance(field.get("alert"), dict) else None
            lines.append("Idle field")
            if transition:
                lines.append(f"Transition: {transition.get('kind', '--')} {transition.get('phase', '--')}")
            elif alert:
                lines.append(f"Alert: {alert.get('kind', '--')} on {alert.get('objectID', '--')}")
            else:
                lines.append(f"Render mode: {field.get('renderMode', '--')}")
        else:
            lines.append(f"Scene: {self._status_value('scene')}")
            lines.append("No active field/battle/dialogue state")

        return [truncate(line, width) for line in lines[:2]]

    def _party_lines(self, width: int) -> list[str]:
        snapshot = self.snapshot or {}
        party = snapshot.get("party")
        pokemon = []
        if isinstance(party, dict) and isinstance(party.get("pokemon"), list):
            pokemon = party["pokemon"][:6]

        if not pokemon:
            return ["No party data"]

        lines = []
        for index, member in enumerate(pokemon, start=1):
            if not isinstance(member, dict):
                continue
            name = member.get("displayName", "--")
            status = member.get("majorStatus", "none")
            moves = member.get("moves") if isinstance(member.get("moves"), list) else []
            line = (
                f"{index}. {name} Lv{member.get('level', '--')} "
                f"HP {member.get('currentHP', '--')}/{member.get('maxHP', '--')} "
                f"status {status} | {', '.join(str(move) for move in moves) if moves else '--'}"
            )
            lines.append(truncate(line, width))
        return lines or ["No party data"]

    def _input_lines(self, width: int) -> list[str]:
        snapshot = self.snapshot or {}
        inputs = snapshot.get("recentInputEvents")
        if not isinstance(inputs, list) or not inputs:
            return ["No recent inputs"]

        formatted = [
            f"{iso_time(item.get('timestamp') if isinstance(item, dict) else None)} {item.get('button', '--')}"
            for item in inputs[-8:]
            if isinstance(item, dict)
        ]
        if not formatted:
            return ["No recent inputs"]

        lines = []
        chunk_size = 4
        for start in range(0, len(formatted), chunk_size):
            lines.append(truncate(" | ".join(formatted[start : start + chunk_size]), width))
        return lines

    def _format_event_line(self, event: dict[str, object]) -> str:
        timestamp = iso_time(str(event.get("timestamp", "")))
        kind = str(event.get("kind", "--"))
        message = str(event.get("message", "--"))
        return f"{timestamp}  {kind:<18} {message}"

    def _event_lines(self, width: int, max_lines: int) -> list[str]:
        if not self.events:
            return ["No live session events yet"]
        return [truncate(self._format_event_line(event), width) for event in list(self.events)[-max_lines:]]

    def _render_dashboard(self) -> None:
        width, height = shutil.get_terminal_size((120, 36))
        content_width = max(40, width - 2)
        header_lines = [
            truncate("PokeSwift Live Watch", content_width),
            truncate(
                f"App PID {self.app_pid} | Telemetry {self._telemetry_state()}",
                content_width,
            ),
            truncate(f"Trace {self.trace_root}", content_width),
            truncate(f"Save {self.save_root}", content_width),
        ]

        snapshot = self.snapshot or {}
        field = snapshot.get("field") if isinstance(snapshot.get("field"), dict) else {}
        audio = snapshot.get("audio") if isinstance(snapshot.get("audio"), dict) else {}
        save = snapshot.get("save") if isinstance(snapshot.get("save"), dict) else {}
        status_line = (
            f"Scene {self._status_value('scene')} | Substate {self._status_value('substate')} | "
            f"Map {field.get('mapName', '--')} [{field.get('mapID', '--')}] | "
            f"Pos {format_position(field.get('playerPosition'))} | Facing {field.get('facing', '--')} | "
            f"Music {audio.get('trackID', '--')} | Save {save.get('canSave', '--')}/{save.get('canLoad', '--')}"
        )

        current_lines = self._current_panel_lines(content_width)
        party_lines = self._party_lines(content_width)
        input_lines = self._input_lines(content_width)

        base_line_count = 10 + len(current_lines) + len(party_lines) + len(input_lines)
        event_budget = max(3, min(12, height - base_line_count))
        event_lines = self._event_lines(content_width, event_budget)

        lines = header_lines + [
            "",
            truncate(status_line, content_width),
            "",
            "Current",
            *current_lines,
            "",
            "Party",
            *party_lines,
            "",
            "Inputs",
            *input_lines,
            "",
            "Events",
            *event_lines,
        ]
        frame = "\n".join(lines)
        sys.stdout.write("\x1b[H\x1b[J")
        sys.stdout.write(frame)
        sys.stdout.flush()

    def _plain_summary(self) -> str:
        snapshot = self.snapshot or {}
        field = snapshot.get("field") if isinstance(snapshot.get("field"), dict) else {}
        audio = snapshot.get("audio") if isinstance(snapshot.get("audio"), dict) else {}
        return (
            f"scene={self._status_value('scene')} "
            f"substate={self._status_value('substate')} "
            f"map={field.get('mapID', '--')} "
            f"pos={format_position(field.get('playerPosition'))} "
            f"music={audio.get('trackID', '--')} "
            f"telemetry={self._telemetry_state()}"
        )

    def _emit_plain_status(self, now: float) -> None:
        summary = self._plain_summary()
        if summary != self._plain_last_summary or (now - self._plain_last_status_at) >= 2.0:
            print(summary, flush=True)
            self._plain_last_summary = summary
            self._plain_last_status_at = now


def main() -> int:
    args = parse_args()
    watcher = LiveSessionWatcher(args)
    return watcher.run()


if __name__ == "__main__":
    raise SystemExit(main())
