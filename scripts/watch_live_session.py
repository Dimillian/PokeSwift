#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request
from collections import deque
from pathlib import Path

try:
    from rich.columns import Columns
    from rich.console import Console, Group
    from rich.live import Live
    from rich.panel import Panel
    from rich.table import Table
    from rich.text import Text
except ModuleNotFoundError:
    Columns = None
    Console = None
    Group = None
    Live = None
    Panel = None
    Table = None
    Text = None


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


def format_position(position: object) -> str:
    if not isinstance(position, dict):
        return "--,--"
    return f"{position.get('x', '--')},{position.get('y', '--')}"


def compact_text(lines: object) -> str:
    if not isinstance(lines, list):
        return ""
    return " / ".join(str(line).strip() for line in lines if str(line).strip())


def bool_label(value: object) -> str:
    if value is True:
        return "yes"
    if value is False:
        return "no"
    return "--"


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
        self.console = Console() if self.tty and Console is not None else None
        signal.signal(signal.SIGTERM, self._request_stop)
        signal.signal(signal.SIGINT, self._request_stop)

    def _request_stop(self, _signum: int, _frame: object) -> None:
        self.stop_requested = True

    def run(self) -> int:
        if self.tty and self.console is None:
            print("rich is required for interactive live watch mode.", file=sys.stderr)
            return 1

        try:
            if self.console is not None and Live is not None:
                return self._run_rich()
            return self._run_plain()
        finally:
            self._close_event_file()

    def _run_rich(self) -> int:
        assert self.console is not None
        assert Live is not None
        with Live(
            self._build_dashboard(),
            console=self.console,
            screen=True,
            auto_refresh=False,
            transient=True,
        ) as live:
            while self.stop_requested is False:
                now = time.monotonic()
                self._poll_snapshot(now)
                self._poll_events()
                live.update(self._build_dashboard(), refresh=True)
                if process_running(self.app_pid) is False:
                    return 0
                time.sleep(self.poll_interval)
        return 130

    def _run_plain(self) -> int:
        while self.stop_requested is False:
            now = time.monotonic()
            self._poll_snapshot(now)
            self._poll_events()
            self._emit_plain_status(now)
            if process_running(self.app_pid) is False:
                return 0
            time.sleep(self.poll_interval)
        return 130

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
            if self.console is None:
                print(self._format_event_line(event), flush=True)

    def _telemetry_state(self) -> str:
        if self.snapshot is not None:
            return "live"
        if self.last_snapshot_success_at is None:
            return f"waiting (file-only): {self.last_snapshot_error}"
        return f"snapshot unavailable: {self.last_snapshot_error}"

    def _telemetry_style(self) -> str:
        if self.snapshot is not None:
            return "green"
        if self.last_snapshot_success_at is None:
            return "yellow"
        return "red"

    def _status_value(self, key: str, default: str = "--") -> str:
        if self.snapshot is None:
            return default
        value = self.snapshot.get(key)
        if value in (None, ""):
            return default
        return str(value)

    def _current_panel_lines(self) -> list[str]:
        snapshot = self.snapshot or {}
        battle = snapshot.get("battle")
        dialogue = snapshot.get("dialogue")
        shop = snapshot.get("shop")
        healing = snapshot.get("fieldHealing")
        prompt = snapshot.get("fieldPrompt")
        field = snapshot.get("field")

        if isinstance(battle, dict):
            trainer = battle.get("trainerName") or battle.get("battleID") or "battle"
            return [
                f"battle {battle.get('kind', '--')} vs {trainer}",
                f"phase {battle.get('phase', '--')}",
                compact_text(battle.get("textLines")) or "battle text --",
            ]
        if isinstance(dialogue, dict):
            return [
                f"dialogue {dialogue.get('dialogueID', '--')}",
                f"page {int(dialogue.get('pageIndex', 0)) + 1}/{dialogue.get('pageCount', '--')}",
                compact_text(dialogue.get("lines")) or "dialogue text --",
            ]
        if isinstance(shop, dict):
            return [
                f"shop {shop.get('title', '--')}",
                f"phase {shop.get('phase', '--')}",
                str(shop.get("promptText") or "prompt --"),
            ]
        if isinstance(healing, dict):
            return [
                f"healing phase {healing.get('phase', '--')}",
                f"balls {healing.get('activeBallCount', '--')}/{healing.get('totalBallCount', '--')}",
                f"nurse {healing.get('nurseObjectID', '--')}",
            ]
        if isinstance(prompt, dict):
            options = prompt.get("options") if isinstance(prompt.get("options"), list) else []
            return [
                f"field prompt {prompt.get('kind', '--')}",
                f"focus {prompt.get('focusedIndex', '--')}",
                f"options {', '.join(str(option) for option in options) if options else '--'}",
            ]
        if isinstance(field, dict):
            transition = field.get("transition") if isinstance(field.get("transition"), dict) else None
            alert = field.get("alert") if isinstance(field.get("alert"), dict) else None
            if transition:
                return ["idle field", f"transition {transition.get('kind', '--')}", f"phase {transition.get('phase', '--')}"]
            if alert:
                return ["idle field", f"alert {alert.get('kind', '--')}", f"object {alert.get('objectID', '--')}"]
            return ["idle field", f"render {field.get('renderMode', '--')}", "no blocking overlay"]
        return [f"scene {self._status_value('scene')}", f"substate {self._status_value('substate')}", "no current runtime details"]

    def _party_rows(self) -> list[tuple[str, str, str, str]]:
        snapshot = self.snapshot or {}
        party = snapshot.get("party")
        pokemon = []
        if isinstance(party, dict) and isinstance(party.get("pokemon"), list):
            pokemon = party["pokemon"][:6]

        rows: list[tuple[str, str, str, str]] = []
        for index, member in enumerate(pokemon, start=1):
            if not isinstance(member, dict):
                continue
            rows.append(
                (
                    str(index),
                    f"{member.get('displayName', '--')} Lv{member.get('level', '--')}",
                    f"{member.get('currentHP', '--')}/{member.get('maxHP', '--')}",
                    ", ".join(str(move) for move in member.get("moves", [])) if isinstance(member.get("moves"), list) else "--",
                )
            )
        return rows

    def _input_rows(self) -> list[tuple[str, str]]:
        snapshot = self.snapshot or {}
        inputs = snapshot.get("recentInputEvents")
        if not isinstance(inputs, list):
            return []
        rows = []
        for item in inputs[-3:]:
            if not isinstance(item, dict):
                continue
            rows.append((iso_time(item.get("timestamp")), str(item.get("button", "--"))))
        return rows

    def _format_event_line(self, event: dict[str, object]) -> str:
        timestamp = iso_time(str(event.get("timestamp", "")))
        kind = str(event.get("kind", "--"))
        message = str(event.get("message", "--"))
        return f"{timestamp}  {kind:<18} {message}"

    def _build_dashboard(self):
        assert Console is not None
        assert Group is not None
        assert Panel is not None
        assert Table is not None
        assert Text is not None
        console = self.console
        assert console is not None

        snapshot = self.snapshot or {}
        field = snapshot.get("field") if isinstance(snapshot.get("field"), dict) else {}
        audio = snapshot.get("audio") if isinstance(snapshot.get("audio"), dict) else {}
        save = snapshot.get("save") if isinstance(snapshot.get("save"), dict) else {}

        title = Text("PokeSwift Live Watch", style="bold cyan")
        title.append(f"  PID {self.app_pid}", style="bold")
        title.append("  telemetry ", style="dim")
        title.append(self._telemetry_state(), style=self._telemetry_style())
        header_meta = Table.grid(expand=True)
        header_meta.add_column(ratio=1)
        header_meta.add_column(ratio=1)
        header_meta.add_row(f"[dim]trace[/] {self.trace_root}", f"[dim]save[/]  {self.save_root}")
        header = Panel(
            Group(
                title,
                header_meta,
            ),
            border_style="cyan",
            padding=(0, 1),
        )

        status = Table.grid(expand=True)
        status.add_column(ratio=1)
        status.add_column(ratio=1)
        status.add_row(
            f"scene [bold]{self._status_value('scene')}[/] / {self._status_value('substate')}",
            f"music [bold]{audio.get('trackID', '--')}[/]",
        )
        status.add_row(
            f"map [bold]{field.get('mapName', '--')}[/] [{field.get('mapID', '--')}]",
            f"save canSave={bool_label(save.get('canSave'))} canLoad={bool_label(save.get('canLoad'))}",
        )
        status.add_row(
            f"pos [bold]{format_position(field.get('playerPosition'))}[/] facing {field.get('facing', '--')}",
            f"render {field.get('renderMode', '--')}",
        )
        status_panel = Panel(status, title="Status", border_style="blue", padding=(0, 1))

        current_table = Table.grid(expand=True)
        current_table.add_column()
        for line in self._current_panel_lines():
            current_table.add_row(line)
        current_panel = Panel(current_table, title="Current", border_style="magenta", padding=(0, 1))

        party_table = Table.grid(expand=True, padding=(0, 1))
        party_table.add_column(style="dim", width=2, justify="right")
        party_table.add_column(ratio=3, min_width=18)
        party_table.add_column(width=10, justify="right")
        party_table.add_column(ratio=4, min_width=18)
        party_rows = self._party_rows()
        if party_rows:
            for row in party_rows:
                party_table.add_row(*row)
        else:
            party_table.add_row("-", "No party data", "--", "--")
        party_panel = Panel(party_table, title="Party", border_style="green", padding=(0, 1))

        input_table = Table.grid(expand=True, padding=(0, 1))
        input_table.add_column(width=8, style="dim")
        input_table.add_column(ratio=1, min_width=8)
        input_rows = self._input_rows()
        if input_rows:
            for row in input_rows:
                input_table.add_row(*row)
        else:
            input_table.add_row("--:--:--", "No recent inputs")
        input_panel = Panel(input_table, title="Inputs", border_style="yellow", padding=(0, 1))

        left_column = Group(status_panel, current_panel)
        right_column = Group(party_panel, input_panel)
        top_grid = Table.grid(expand=True)
        top_grid.add_column(ratio=3, min_width=56)
        top_grid.add_column(ratio=2, min_width=36)
        top_grid.add_row(left_column, right_column)

        event_table = Table.grid(expand=True, padding=(0, 1))
        event_table.add_column(width=8, style="dim")
        event_table.add_column(width=18, style="cyan")
        event_table.add_column(ratio=1)
        if self.events:
            for event in self.events:
                event_table.add_row(
                    iso_time(str(event.get("timestamp", ""))),
                    str(event.get("kind", "--")),
                    str(event.get("message", "--")),
                )
        else:
            event_table.add_row("--:--:--", "waiting", "No live session events yet")

        events_panel = Panel(event_table, title="Events", border_style="red", padding=(0, 1))

        return Group(header, top_grid, events_panel)

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
