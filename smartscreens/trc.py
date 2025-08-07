from utils.banner import show_banner
from scanner import scan_target
from exploits.ws_control import execute_ws_action
from exploits.http_api import execute_http_action
import json

def main():
    show_banner()
    ip = input("[+] Enter Target IP: ")
    port = input("[+] Enter Target Port: ")

    print("\n[*] Scanning Target...")
    result = scan_target(ip, port)

    if not result:
        print("[!] No exploitable services found.")
        return

    print("\n[!!] Exploitable Functions Found:")
    for idx, item in enumerate(result['actions']):
        print(f"   [{idx+1}] {item['name']}")

    choice = int(input("\n[>] Select action to perform: ")) - 1
    action = result['actions'][choice]

    if action['type'] == 'ws':
        execute_ws_action(ip, port, action)
    else:
        execute_http_action(ip, port, action)

if __name__ == "__main__":
    main()
