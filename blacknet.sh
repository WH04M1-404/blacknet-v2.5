#!/bin/bash


RED='\033[1;31m'
GREEN='\033[1;32m'
LIME='\033[1;92m'
NC='\033[0m' # No Color

# Get terminal dimensions
ROWS=$(tput lines)
COLS=$(tput cols)

center_text() {
  local text="$1"
  local width=${#text}
  local pad=$(( (COLS - width) / 2 ))
  printf "%*s%s\n" $pad "" "$text"
}

draw_banner() {
  local banner=(
"███B██╗   ██╗      ██╗  ██╗  ██████╗  ██╗  ██╗ -------- ███╗   ██   █████    ████T███╗"
"██╔══██╗  ██║      ██║  ██║ ██╔════╝  ██║ ██╔╝ BL4CKN3T █N██╗  ██║  ╚════██  ╚══██╔══╝"
"██████╔╝  ██║      ███4███║ C ║       ███K█╔╝ FR4M3WORK ██╔██╗ ██║  ███3█╔╝     ██║   "
"██╔══██╗  ██║      ╚════██║ ██║       ██╔═██╗    V1.7   ██║╚██╗██║  ╚═══██╗     ██║   "
"██████╔╝  ████L██╗      ██║ ╚██████   ██║  ██╗ -------- ██║ ╚████║  ██████╔     ██║   "
"╚═════╝   ╚══════╝      ╚═╝  ╚═════╝  ╚═╝  ╚═╝          ╚═╝  ╚═══╝  ╚═════╝     ╚═╝   "
"                  WIRELESS ATTACKS FRAMEWORK DEVELOPED BY WH04M1                      "
"                      -------------------------------------                           "
"   WIFI CRACKING - WORDLIST GENERATING - EVIL TWIN ATTACKS - TV HACKING - GUI & CLI   "

  )

  clear
  local start_row=$(( (ROWS - ${#banner[@]}) / 4 ))
  for line in "${banner[@]}"; do
    tput cup $start_row 0
    echo -e "${RED}$(center_text "$line")${NC}"
    ((start_row++))
    sleep 0.1
  done
}

draw_menu() {
  sleep 0.4
  local options=(
    "[1] Evil Twin - Sniffing"
    "[2] Wordlist Generate CLI"
    "[3] Wordlist Generate GUI"
    "[4] Handshake capture CLI"
    "[5] Handshake capture GUI"
    "[6] Smart Screens attack"
    "[7] Beacon attack"
  )

  local start_row=$((ROWS / 2))
  for opt in "${options[@]}"; do
    tput cup $start_row 0
    echo -e "$(center_text "${GREEN}${opt}${NC}")"
    ((start_row+=2))  # Space between options
    sleep 0.1
  done
}

main() {
  draw_banner
  draw_menu

  tput cup $((ROWS - 2)) 0
  echo -ne "${LIME}<BL4CKN3T~#> ${NC}"
  read choice

  case $choice in
  1)
    cd eviltwin || exit
    chmod +x blacktwin.sh
    ./blacktwin.sh
    ;;
  2)
    cd generate/CLI || exit
    python3 crackmypass.py
    ;;
  3)
    cd generate/GUI || exit
    python3 blacklist.py
    ;;
  4)
    cd wificrack/CLI || exit
    chmod +x blackwifi.sh
    ./blackwifi.sh
    ;;
  5)
    cd wificrack/GUI || exit
    python3 blackwifi.py
    ;;
  6)
    cd smartscreens || exit
    python3 darkscreen.py
    ;;
  7)
    cd beacon_attack || exit
    chmod +x blackvision.sh
    ./blackvision.sh
    ;;
  *)
    echo -e "${RED}[!] Invalid option. Exiting...${NC}"
    ;;
esac
}

main  
