#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

RESULT_FILE="wireless_iot_results.json"
MAC_FILE="macs.txt"
SCAN_FILE="scan_results-01.csv"
INTERFACE=""
TIMEOUT=60
declare -A KNOWN_OUIS
declare -A MAC_COUNT
declare -A ALERTED_OUIS
declare -A SEEN_MACS


load_ouis() {
    if [ ! -f "$MAC_FILE" ]; then
        echo -e "${RED}[!] OUI file not found: $MAC_FILE${NC}"
        exit 1
    fi
    while read -r line; do
        [[ "$line" =~ ^# ]] && continue
        OUI=$(echo $line | awk '{print $1}' | tr '[:lower:]' '[:upper:]')
        VENDOR=$(echo $line | awk '{print $2}')
        KNOWN_OUIS[$OUI]=$VENDOR
    done < $MAC_FILE
    echo -e "${GREEN}[+] Loaded ${#KNOWN_OUIS[@]} known OUIs${NC}"
}

get_vendor() {
    local mac="$1"
    local oui=$(echo $mac | cut -d: -f1-3 | tr '[:lower:]' '[:upper:]')
    if [[ -n "${KNOWN_OUIS[$oui]}" ]]; then
        echo "${KNOWN_OUIS[$oui]}"
    else
        echo "Unknown"
    fi
}

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "============================================"
    echo "   External IoT Device Detector (iotex)"
    echo "============================================"
    echo -e "${NC}"
}

choose_network() {
    echo -e "${YELLOW}Enter monitor mode interface (e.g., wlan0mon): ${NC}"
    read INTERFACE
    if [ -z "$INTERFACE" ]; then
        echo -e "${RED}[!] No interface provided.${NC}"
        exit 1
    fi

    echo -e "${GREEN}[+] Launching airodump-ng... close window when ready.${NC}"
    xterm -hold -e "airodump-ng $INTERFACE --output-format csv -w scan_results" &

    echo -e "${YELLOW}Press Enter after closing airodump-ng window...${NC}"
    read

    if [ ! -f "$SCAN_FILE" ]; then
        echo -e "${RED}[!] No scan file found (${SCAN_FILE}).${NC}"
        exit 1
    fi

    echo -e "${BLUE}[+] Available Networks:${NC}"
    awk -F',' 'NR>2 && $1!="" && $1!="Station MAC" {printf "%d) %s | %s\n", NR-2, $14, $1}' $SCAN_FILE

    echo -e "${YELLOW}Choose network number:${NC}"
    read CHOICE
    SSID=$(awk -F',' -v num=$CHOICE 'NR==num+2 {print $14}' $SCAN_FILE)
    BSSID=$(awk -F',' -v num=$CHOICE 'NR==num+2 {print $1}' $SCAN_FILE)
    CHANNEL=$(awk -F',' -v num=$CHOICE 'NR==num+2 {print $4}' $SCAN_FILE)

    echo -e "${GREEN}[+] Selected: $SSID ($BSSID) Channel $CHANNEL${NC}"
    iwconfig $INTERFACE channel $CHANNEL
}

start_attack_log() {
    echo -e "${BLUE}[+] Monitoring for IoT devices (max ${TIMEOUT}s)...${NC}"
    echo "[" > $RESULT_FILE

    DETECTED_IOT=0
    END_TIME=$((SECONDS+TIMEOUT))

    tshark -i $INTERFACE -Y "wlan.fc.type_subtype==8 || wlan.fc.type_subtype==5" -T fields -e wlan.sa 2>/dev/null | while read MAC; do
        [ -z "$MAC" ] && continue
        [[ $SECONDS -ge $END_TIME ]] && break

        if [[ -n "${SEEN_MACS[$MAC]}" ]]; then
            continue
        fi
        SEEN_MACS[$MAC]=1

        OUI=$(echo $MAC | cut -d: -f1-3 | tr '[:lower:]' '[:upper:]')
        VENDOR=$(get_vendor "$MAC")

        MAC_COUNT[$OUI]=$(( ${MAC_COUNT[$OUI]:-0} + 1 ))

        echo -e "${GREEN}[+] New Device:${NC} $MAC | Vendor:${VENDOR}"

        if [ "$VENDOR" != "Unknown" ]; then
            echo -e "${BLUE}[!] IoT Device Detected (${VENDOR})${NC}"
            DETECTED_IOT=1
            kill $PPID
        fi

        if [ ${MAC_COUNT[$OUI]} -ge 3 ] && [ -z "${ALERTED_OUIS[$OUI]}" ]; then
            echo -e "${RED}[!] Multiple devices with OUI $OUI (${MAC_COUNT[$OUI]} devices) → Possible Camera Cluster!${NC}"
            ALERTED_OUIS[$OUI]=1
        fi

        echo "  {\"mac\": \"$MAC\", \"vendor\": \"$VENDOR\", \"oui\": \"$OUI\"}," >> $RESULT_FILE
    done
}

trap finish EXIT
finish() {
    echo "]" >> $RESULT_FILE
    if [ $DETECTED_IOT -eq 1 ]; then
        echo -e "${GREEN}[+] IoT Device Found. Stopping Scan.${NC}"
    else
        echo -e "${YELLOW}[!] No IoT devices found after $TIMEOUT seconds.${NC}"
    fi
    echo -e "${BLUE}[+] Results saved to $RESULT_FILE${NC}"
}

# MAIN
show_banner
load_ouis
choose_network
start_attack_log
