#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

RESULT_FILE="iot_results.json"

for cmd in nmap jq xmllint; do
    command -v $cmd >/dev/null 2>&1 || { echo -e "${RED}Error:${NC} $cmd not installed. Install it and retry."; exit 1; }
done

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "========================================="
    echo "       IoT Detector Internal (iotin)"
    echo "========================================="
    echo -e "${NC}"
}

show_menu() {
    echo -e "${YELLOW}Select an option:${NC}"
    echo "1) Quick Scan (Top 1000 Ports)"
    echo "2) Full Port Scan (1-65535)"
    echo "3) Show Last Results"
    echo "4) Exit"
    echo -n "Enter choice: "
}

perform_scan() {
    SCAN_TYPE=$1
    echo -e "${YELLOW}Enter target network (e.g., 192.168.1.0/24): ${NC}"
    read NET

    echo -e "${BLUE}[+] Scan started on $NET ...${NC}"
    START_TIME=$(date +%s.%N)

    if [ "$SCAN_TYPE" == "quick" ]; then
        echo -e "${BLUE}[+] Mode: Quick Scan${NC}"
        nmap -sV -T4 --open $NET -oX iot_scan.xml >/dev/null
    else
        echo -e "${BLUE}[+] Mode: Full Scan${NC}"
        nmap -sV -p1-65535 -T4 --open $NET -oX iot_scan.xml >/dev/null
    fi

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc)
    echo -e "${GREEN}[+] Scan completed in ${DURATION}s${NC}"

    parse_results
}

parse_results() {
    HOSTS=$(xmllint --xpath "//host" iot_scan.xml 2>/dev/null)

    if [ -z "$HOSTS" ]; then
        echo -e "${RED}[+] No devices found.${NC}"
        return
    fi

    echo "[" > $RESULT_FILE
    COUNT=0

    echo -e "\n${YELLOW}IoT Suspected Devices:${NC}"
    echo -e "${BLUE}IP Address        | Open Ports       | Services            | Vendor${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------------${NC}"

    for IP in $(xmllint --xpath "//address[@addrtype='ipv4']/@addr" iot_scan.xml | sed 's/addr="/\n/g' | sed 's/"//g' | tail -n +2); do
        MAC=$(xmllint --xpath "//host[address[@addr='$IP']]/address[@addrtype='mac']/@addr" iot_scan.xml 2>/dev/null | sed 's/addr="//g' | sed 's/"//g')
        VENDOR=$(xmllint --xpath "//host[address[@addr='$IP']]/address[@addrtype='mac']/@vendor" iot_scan.xml 2>/dev/null | sed 's/vendor="//g' | sed 's/"//g')
        PORTS=$(xmllint --xpath "//host[address[@addr='$IP']]/ports/port[state/@state='open']/@portid" iot_scan.xml 2>/dev/null | sed 's/portid="/\n/g' | sed 's/"//g' | tail -n +2 | paste -sd "," -)
        SERVICES=$(xmllint --xpath "//host[address[@addr='$IP']]/ports/port[state/@state='open']/service/@name" iot_scan.xml 2>/dev/null | sed 's/name="/\n/g' | sed 's/"//g' | tail -n +2 | paste -sd "," -)

        DETECTED=false
        
        if echo "$SERVICES" | grep -Eqi "rtsp|upnp|ssdp|websocket|mqtt|onvif"; then
            DETECTED=true
        fi
        if echo "$PORTS" | grep -Eq "554|8554|1900|5000|8080"; then
            DETECTED=true
        fi
        if echo "$VENDOR" | grep -Eqi "hikvision|dahua|tplink|d-link|netgear|sony|axis|huawei"; then
            DETECTED=true
        fi

        
        [ $COUNT -gt 0 ] && echo "," >> $RESULT_FILE
        echo "  {" >> $RESULT_FILE
        echo "    \"ip\": \"$IP\"," >> $RESULT_FILE
        echo "    \"mac\": \"${MAC:-Unknown}\"," >> $RESULT_FILE
        echo "    \"vendor\": \"${VENDOR:-Unknown}\"," >> $RESULT_FILE
        echo "    \"open_ports\": \"${PORTS:-None}\"," >> $RESULT_FILE
        echo "    \"services\": \"${SERVICES:-None}\"" >> $RESULT_FILE
        echo -n "  }" >> $RESULT_FILE
        COUNT=$((COUNT+1))

        
        if [ "$DETECTED" == true ]; then
            echo -e "${GREEN}$IP${NC} | $PORTS | $SERVICES | ${VENDOR:-Unknown}"
        fi
    done

    echo "]" >> $RESULT_FILE
    echo -e "\n${GREEN}[+] Full results saved to $RESULT_FILE${NC}"
}

show_results() {
    if [ -f "$RESULT_FILE" ]; then
        echo -e "${BLUE}[*] Last Scan Results:${NC}"
        jq . $RESULT_FILE
    else
        echo -e "${RED}No previous results found.${NC}"
    fi
}

while true; do
    show_banner
    show_menu
    read CHOICE
    case $CHOICE in
        1) perform_scan "quick" ;;
        2) perform_scan "full" ;;
        3) show_results ;;
        4) echo -e "${BLUE}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice. Try again.${NC}" ;;
    esac
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
done
