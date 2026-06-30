#!/usr/bin/env python3
#Author: Praneeth_Perera

import csv
import sys
from pathlib import Path
from datetime import datetime

def process_report(input_file: str, output_file: str = None):
    input_path = Path(input_file)
    if not input_path.exists():
        print("Input file not found.")
        return

    processed = []
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        reader = csv.reader(f)
        header = next(reader, None)
        if header:
            processed.append(header + ['Processed_Date'])

        for row in reader:
            if len(row) >= 2:
                row.append(datetime.now().strftime("%Y-%m-%d"))
                processed.append(row)

    out_path = Path(output_file) if output_file else input_path.with_name(f"processed_{input_path.name}")
    with open(out_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(processed)

    print(f"Processed {len(processed)-1} rows → {out_path}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python file_processor.py <input.csv> [output.csv]")
        sys.exit(1)
    process_report(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)

