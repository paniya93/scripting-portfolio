#!/usr/bin/env python3
#Author: Praneeth_Perera

import re
from collections import Counter
from pathlib import Path
import sys
from datetime import datetime


def analyze_log(log_path: str, custom_patterns=None):
    """
    Analyzes any text-based log file and extracts useful statistics.
    
    Args:
        log_path (str): Path to the log file
        custom_patterns (dict): Optional custom regex patterns
    """
    log_path = Path(log_path)
    if not log_path.exists():
        print(f"Error: Log file not found: {log_path}")
        return

    stats = {
        'total_lines': 0,
        'errors': 0,
        'warnings': 0,
        'info': 0,
        'custom_events': Counter()
    }

    # Default patterns
    patterns = {
        'error': re.compile(r'(ERROR|ERR|Exception|Failed|Traceback)', re.IGNORECASE),
        'warning': re.compile(r'(WARN|WARNING)', re.IGNORECASE),
        'info': re.compile(r'(INFO|DEBUG)', re.IGNORECASE),
    }

    # Add custom patterns if provided
    if custom_patterns:
        patterns.update(custom_patterns)

    with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            stats['total_lines'] += 1
            
            for event, pattern in patterns.items():
                if pattern.search(line):
                    stats['custom_events'][event] += 1
                    if event == 'error':
                        stats['errors'] += 1
                    elif event == 'warning':
                        stats['warnings'] += 1
                    elif event == 'info':
                        stats['info'] += 1

    # Display results
    print(f"\n=== Log Analysis Report ===")
    print(f"File          : {log_path.name}")
    print(f"Analyzed on   : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Total Lines   : {stats['total_lines']:,}\n")
    print(f"Errors        : {stats['errors']}")
    print(f"Warnings      : {stats['warnings']}")
    print(f"Info Messages : {stats['info']}")
    print("-" * 40)

    # Show top custom events
    if stats['custom_events']:
        print("\nTop Events:")
        for event, count in stats['custom_events'].most_common(10):
            print(f"  {event:15} : {count}")

    print("\nScript by Praneeth")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python log_analyzer.py <logfile.log>")
        print("Example: python log_analyzer.py /var/log/application.log")
        sys.exit(1)
    
    analyze_log(sys.argv[1])

