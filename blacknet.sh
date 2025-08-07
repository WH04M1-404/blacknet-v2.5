#!/bin/bash

# Colors
RED='\033[1;31m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_DIR=$(pwd)

show_banner() {
    clear
    banner_lines=(
"${RED}███B██╗   ██╗${BLUE}      ██╗  ██╗  ██████╗  ██╗  ██╗ -------- ███╗   ██   █████    ████T███╗${NC}"
"${RED}██╔══██╗  ██║${BLUE}      ██║  ██║ ██╔════╝  ██║ ██╔╝ ${RED}BL4CK${BLUE}N3T █N██╗  ██║  ╚════██  ╚══██╔══╝${NC}"
"${RED}██████╔╝  ██║${BLUE}      ███4███║ C ║       ███K█╔╝ FR4M3WORK ██╔██╗ ██║  ███3█╔╝     ██║${NC}"
"${RED}██╔══██╗  ██║${BLUE}      ╚════██║ ██║       ██╔═██╗    V2.5   ██║╚██╗██║  ╚═══██╗     ██║${NC}"
"${RED}██████╔╝  ████L██╗${BLUE}      ██║ ╚██████   ██║  ██╗ -------- ██║ ╚████║  ██████╔     ██║${NC}"
"${RED}╚═════╝   ╚══════╝${BLUE}      ╚═╝  ╚═════╝  ╚═╝  ╚═╝          ╚═╝  ╚═══╝  ╚═════╝     ╚═╝${NC}"
"${BLUE}WIRELESS ATTACKS FRAMEWORK DEVELOPED BY WH04M1${NC}"
"${BLUE}-----------------------------------------------${NC}"
"${BLUE}GITHUB : https://github.com/WH04M1-404${NC}"
    )

    row=2
    for line in "${banner_lines[@]}"; do
        tput cup $row 5
        echo -e "$line"
        row=$((row+1))
        sleep 0.08
    done
    echo
}

show_menu() {
    show_banner
    echo -e "
${YELLOW}[01] Evil Twin - Sniffing${NC}        ${YELLOW}[02] Wordlist Generate CLI${NC}
${YELLOW}[03] Wordlist Generate GUI${NC}       ${YELLOW}[04] Handshake capture CLI${NC}
${YELLOW}[05] Handshake capture GUI${NC}       ${YELLOW}[06] Smart Screens attack${NC}
${YELLOW}[07] Beacon attack${NC}               ${YELLOW}[08] Smart Traceroute${NC}
${YELLOW}[09] Fast Scan${NC}                   ${YELLOW}[10] Fast Scan + Ports${NC}
${YELLOW}[11] IoT Hunt internal${NC}           ${YELLOW}[12] IoT Hunt external${NC}
${YELLOW}[13] Smart WPS cracker (UNDER TEST)${NC}
"
    echo -ne "${YELLOW}<BL4CKN3T~#> ${NC}"
}

post_action_menu() {
    echo
    echo -e "${YELLOW}[1] Leave BL4CKN3T${NC}"
    echo -e "${YELLOW}[2] Return to menu${NC}"
    echo -ne "${YELLOW}Choose: ${NC}"
    read after_choice
    case $after_choice in
        1) echo -e "${RED}THANKS FOR SHOPPING WITH BL4CKN3T!${NC}"; exit 0 ;;
        2) main_menu ;;
        *) echo -e "${RED}[!] Invalid option. Returning to menu...${NC}"; sleep 1; main_menu ;;
    esac
}

trap ctrl_c INT
ctrl_c() {
    echo -e "\n${RED}[!] Detected Ctrl+C!${NC}"
    post_action_menu
}

main_menu() {
    show_menu
    read choice
    case $choice in
      1) cd "$BASE_DIR/eviltwin" && chmod +x blacktwin.sh && ./blacktwin.sh ;;
      2) cd "$BASE_DIR/generate/CLI" && python3 crackmypass.py ;;
      3) cd "$BASE_DIR/generate/GUI" && python3 blacklist.py ;;
      4) cd "$BASE_DIR/wificrack/CLI" && chmod +x blackwifi.sh && ./blackwifi.sh ;;
      5) cd "$BASE_DIR/wificrack/GUI" && python3 blackwifi.py ;;
      6) cd "$BASE_DIR/smartscreens" && python3 trc.py ;;
      7) cd "$BASE_DIR/beacon_attack" && chmod +x blackvision.sh && ./blackvision.sh ;;
      8) cd "$BASE_DIR/rc" && chmod +x trrt.sh && ./trrt.sh ;;
      9) cd "$BASE_DIR/rc" && chmod +x whonet.sh && ./whonet.sh ;;
      10) cd "$BASE_DIR/rc" && chmod +x whonetp.sh && ./whonetp.sh ;;
      11) cd "$BASE_DIR/iot/internal" && chmod +x iotin.sh && ./iotin.sh ;;
      12) cd "$BASE_DIR/iot/external" && chmod +x iotex.sh && ./iotex.sh ;;
      13) cd "$BASE_DIR/wps" && python3 wph.py ;;
      *) echo -e "${RED}[!] Invalid option. Returning...${NC}"; sleep 1 ;;
    esac
    post_action_menu
}

main_menu
