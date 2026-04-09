#!/usr/bin/env python3
"""Post-flight session summary for Claude Code.

Fires as a Stop hook and prints an interaction summary similar to Gemini CLI.
"""

import json
import sys
from collections import defaultdict
from datetime import datetime, timezone

# ANSI color codes
CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"


def fmt_duration(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    if h > 0:
        return f"{h}h {m}m {s}s"
    if m > 0:
        return f"{m}m {s}s"
    return f"{s}s"


def fmt_num(n: int) -> str:
    return f"{n:,}"


def parse_transcript(path: str) -> dict:
    stats = {
        "tool_calls": [],
        "tool_results": {},
        "models": defaultdict(lambda: {"reqs": 0, "input": 0, "cache_read": 0, "cache_create": 0, "output": 0}),
        "timestamps": [],
        "turns": 0,
    }

    try:
        with open(path) as f:
            lines = [json.loads(l.strip()) for l in f if l.strip()]
    except (OSError, json.JSONDecodeError):
        return stats

    for obj in lines:
        if "timestamp" in obj:
            try:
                stats["timestamps"].append(
                    datetime.fromisoformat(obj["timestamp"].replace("Z", "+00:00"))
                )
            except ValueError:
                pass

        msg_type = obj.get("type", "")
        msg = obj.get("message", {})

        if msg_type == "assistant" and isinstance(msg, dict):
            model = msg.get("model", "unknown")
            usage = msg.get("usage", {})

            # Only count unique message IDs to avoid duplicate records
            msg_id = msg.get("id", "")
            if not msg_id or msg_id not in stats.get("_seen_msgs", set()):
                if "_seen_msgs" not in stats:
                    stats["_seen_msgs"] = set()
                if msg_id:
                    stats["_seen_msgs"].add(msg_id)

                stats["models"][model]["reqs"] += 1
                stats["models"][model]["input"] += usage.get("input_tokens", 0)
                stats["models"][model]["cache_read"] += usage.get("cache_read_input_tokens", 0)
                stats["models"][model]["cache_create"] += (
                    usage.get("cache_creation_input_tokens", 0)
                )
                stats["models"][model]["output"] += usage.get("output_tokens", 0)

            content = msg.get("content", [])
            for item in content:
                if isinstance(item, dict) and item.get("type") == "tool_use":
                    stats["tool_calls"].append(
                        {"id": item.get("id", ""), "name": item.get("name", "")}
                    )

            stats["turns"] += 1

        # Track tool results to detect failures
        elif msg_type == "user" and isinstance(msg, dict):
            content = msg.get("content", [])
            if isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_result":
                        tool_id = item.get("tool_use_id", "")
                        is_error = item.get("is_error", False)
                        if tool_id:
                            stats["tool_results"][tool_id] = is_error

    return stats


def main() -> None:
    raw = sys.stdin.read()
    hook_data = {}
    if raw.strip():
        try:
            hook_data = json.loads(raw)
        except json.JSONDecodeError:
            pass

    session_id = hook_data.get("session_id", "unknown")
    transcript_path = hook_data.get("transcript_path", "")
    cwd = hook_data.get("cwd", "")

    stats = parse_transcript(transcript_path) if transcript_path else {}

    tool_calls = stats.get("tool_calls", [])
    tool_results = stats.get("tool_results", {})
    models = stats.get("models", {})
    timestamps = stats.get("timestamps", [])

    total_calls = len(tool_calls)
    failed_calls = sum(1 for tc in tool_calls if tool_results.get(tc["id"], False))
    success_calls = total_calls - failed_calls
    success_rate = (success_calls / total_calls * 100) if total_calls else 100.0

    wall_secs = 0.0
    if len(timestamps) >= 2:
        wall_secs = (max(timestamps) - min(timestamps)).total_seconds()

    total_input = sum(m["input"] for m in models.values())
    total_cache_read = sum(m["cache_read"] for m in models.values())
    total_cache_create = sum(m["cache_create"] for m in models.values())
    total_output = sum(m["output"] for m in models.values())
    total_reqs = sum(m["reqs"] for m in models.values())

    cache_savings_pct = (
        total_cache_read / (total_input + total_cache_read) * 100
        if (total_input + total_cache_read) > 0
        else 0.0
    )

    print()
    print(f"{BOLD}Previous Session{RESET}")
    print()

    label_w = 20
    print(f"{CYAN}{'Session ID:':<{label_w}}{RESET}{session_id}")
    print(
        f"{CYAN}{'Tool Calls:':<{label_w}}{RESET}"
        f"{total_calls}  ( {GREEN}✓ {success_calls}{RESET} x {RED}✗ {failed_calls}{RESET} )"
    )
    print(f"{CYAN}{'Success Rate:':<{label_w}}{RESET}{success_rate:.1f}%")
    print(f"{CYAN}{'Requests:':<{label_w}}{RESET}{total_reqs}")

    print()
    print(f"{BOLD}Performance{RESET}")
    print(f"{CYAN}{'Wall Time:':<{label_w}}{RESET}{fmt_duration(wall_secs)}")
    if total_input + total_cache_read + total_output > 0:
        print(f"{CYAN}{'Input Tokens:':<{label_w}}{RESET}{fmt_num(total_input)}")
        print(f"{CYAN}{'Output Tokens:':<{label_w}}{RESET}{fmt_num(total_output)}")

    if models:
        print()
        col_model = 32
        col_reqs = 6
        col_input = 14
        col_cache_r = 14
        col_cache_c = 16
        col_output = 14

        header = (
            f"{'Model':<{col_model}}"
            f"{'Reqs':>{col_reqs}}"
            f"{'Input Tokens':>{col_input}}"
            f"{'Cache Reads':>{col_cache_r}}"
            f"{'Cache Created':>{col_cache_c}}"
            f"{'Output Tokens':>{col_output}}"
        )
        print(f"{BOLD}{header}{RESET}")
        print(DIM + "-" * len(header) + RESET)
        for model_name, m in sorted(models.items()):
            row = (
                f"{model_name:<{col_model}}"
                f"{m['reqs']:>{col_reqs}}"
                f"{fmt_num(m['input']):>{col_input}}"
                f"{fmt_num(m['cache_read']):>{col_cache_r}}"
                f"{fmt_num(m['cache_create']):>{col_cache_c}}"
                f"{fmt_num(m['output']):>{col_output}}"
            )
            print(row)

    if total_cache_read > 0:
        print()
        print(
            f"{DIM}Savings Highlight: {fmt_num(total_cache_read)} "
            f"({cache_savings_pct:.1f}%) of input tokens were served from cache, "
            f"reducing costs.{RESET}"
        )

    print()
    print(
        f"{CYAN}To resume this session: "
        f"claude --resume {session_id}{RESET}"
    )
    print()


if __name__ == "__main__":
    main()
