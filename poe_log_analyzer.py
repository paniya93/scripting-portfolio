#!/usr/bin/env python3
#Author: Praneeth_Perera

import re
from collections import Counter
from pathlib import Path
import sys
from datetime import datetime

def analyze_poe_log(log_path: str):
    log_path = Path(log_path)
    if not log_path.exists():
        print("Log file not found.")
        return

    deaths = 0
    level_ups = 0
    map_completions = 0
    error_count = 0

    patterns = {
        "death": re.compile(r"You have been slain", re.IGNORECASE),
        "level_up": re.compile(r"(\w+) is now level (\d+)"),
        "map_complete": re.compile(r"Area \d+-\d+ has been completed"),
        "error": re.compile(r"(ERROR|Exception|Failed|Traceback)", re.IGNORECASE),
    }

    with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            for event, pattern in patterns.items():
                if pattern.search(line):
                    if event == "death":
                        deaths += 1
                    elif event == "level_up":
                        level_ups += 1
                    elif event == "map_complete":
                        map_completions += 1
                    elif event == "error":
                        error_count += 1

    print(f"\n=== Path of Exile Log Analysis ===")
    print(f"File: {log_path.name}")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
    print(f"Total Deaths          : {deaths}")
    print(f"Level Ups             : {level_ups}")
    print(f"Map Completions       : {map_completions}")
    print(f"Errors / Warnings     : {error_count}")
    print("\nScript by Praneeth")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python poe_log_analyzer.py <client.txt>")
        sys.exit(1)
    analyze_poe_log(sys.argv[1])

