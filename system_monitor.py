#!/usr/bin/env python3
#Author: Praneeth_Perera

import psutil
import time
from datetime import datetime
from pathlib import Path

def monitor_system(interval: int = 60, duration: int = 300):
    log_file = Path("system_monitor.log")
    
    print(f"Starting system monitoring for {duration//60} minutes...")

    with open(log_file, "a", encoding="utf-8") as log:
        log.write(f"=== Monitoring Started: {datetime.now()} ===\n")
        
        for _ in range(duration // interval):
            cpu = psutil.cpu_percent(interval=1)
            mem = psutil.virtual_memory().percent
            disk = psutil.disk_usage('/').percent
            
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            line = f"{timestamp} | CPU: {cpu:5.1f}% | RAM: {mem:5.1f}% | Disk: {disk:5.1f}%"
            
            print(line)
            log.write(line + "\n")
            
            if cpu > 90 or mem > 90:
                print("⚠️  HIGH RESOURCE USAGE ALERT!")
            
            time.sleep(interval)

    print(f"Monitoring finished. Log saved to {log_file}")


if __name__ == "__main__":
    monitor_system()

