#!/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"

TOKEN_FILE="./token.txt"


if [[ ! -f "$TOKEN_FILE" ]]; then
    echo -e "${YELLOW}[?] Enter your ipinfo.io API token:${RESET}"
    read user_token
    echo "$user_token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}[+] Token saved successfully in token.txt${RESET}\n"
fi


API_TOKEN=$(cat "$TOKEN_FILE" | tr -d ' \n')

# Validate token
if [[ -z "$API_TOKEN" ]]; then
    echo -e "${RED}[!] No API token found in token.txt. Please add it manually.${RESET}"
    exit 1
fi

echo -e "${BLUE}Enter the target domain or IP for traceroute:${RESET}"
read target

my_ip=$(hostname -I | awk '{print $1}')
gateway=$(ip route | grep default | awk '{print $3}')
target_ip=$(getent ahosts $target | awk '{print $1; exit}')

echo -e "\n${BLUE}Your IP: $my_ip${RESET}"
echo -e "${BLUE}Gateway: $gateway${RESET}"
echo -e "${BLUE}Target: $target ($target_ip)${RESET}"
echo -e "${YELLOW}Starting traceroute to $target ...${RESET}\n"
echo -e "--------------------------------------------------------------------------------------"
printf "${BLUE}%-6s${RESET} ${GREEN}%-15s${RESET} ${YELLOW}%-35s${RESET} ${CYAN}%-10s${RESET} ${MAGENTA}%-30s${RESET}\n" "Hop" "IP" "RDNS" "Country" "ISP"
echo -e "--------------------------------------------------------------------------------------"

trace=$(traceroute -n $target)
hop_count=0

echo "$trace" | tail -n +2 | while read -r line; do
    hop_count=$((hop_count+1))
    ip=$(echo $line | awk '{print $2}')

    if [[ -z "$ip" || "$ip" == "*" ]]; then
        printf "${RED}%-6s %-15s %-35s %-10s %-30s${RESET}\n" "$hop_count" "No Reply" "-" "-" "-"
        continue
    fi

    if [[ "$ip" == "$target_ip" ]]; then
        rdns=$(host $ip 2>/dev/null | awk '/domain name pointer/ {print $5}' | sed 's/\.$//')
        [ -z "$rdns" ] && rdns="N/A"

        ipinfo=$(curl -s "https://ipinfo.io/$ip?token=$API_TOKEN")
        country=$(echo $ipinfo | jq -r '.country // "Unknown"')
        org=$(echo $ipinfo | jq -r '.org // "Unknown"')

        printf "${BLUE}%-6s${RESET} ${GREEN}%-15s${RESET} ${YELLOW}%-35s${RESET} ${CYAN}%-10s${RESET} ${MAGENTA}%-30s${RESET}\n" "$hop_count" "$ip" "$rdns" "$country" "$org"
        echo -e "--------------------------------------------------------------------------------------"
        echo -e "${GREEN}Destination reached at hop $hop_count. Stopping traceroute.${RESET}"
        exit 0
    fi

    rdns=$(host $ip 2>/dev/null | awk '/domain name pointer/ {print $5}' | sed 's/\.$//')
    [ -z "$rdns" ] && rdns="N/A"

    if [[ $ip =~ ^10\. || $ip =~ ^192\.168\. || $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
        if [[ $hop_count -eq 1 ]]; then
            printf "${BLUE}%-6s${RESET} ${GREEN}%-15s${RESET} ${YELLOW}%-35s${RESET} ${CYAN}%-10s${RESET} ${MAGENTA}%-30s${RESET}\n" "$hop_count" "$ip" "$rdns" "Private" "Gateway"
        else
            printf "${BLUE}%-6s${RESET} ${GREEN}%-15s${RESET} ${YELLOW}%-35s${RESET} ${CYAN}%-10s${RESET} ${MAGENTA}%-30s${RESET}\n" "$hop_count" "$ip" "$rdns" "Private" "Internal ISP"
        fi
    else
        ipinfo=$(curl -s "https://ipinfo.io/$ip?token=$API_TOKEN")
        country=$(echo $ipinfo | jq -r '.country // "Unknown"')
        org=$(echo $ipinfo | jq -r '.org // "Unknown"')

        printf "${BLUE}%-6s${RESET} ${GREEN}%-15s${RESET} ${YELLOW}%-35s${RESET} ${CYAN}%-10s${RESET} ${MAGENTA}%-30s${RESET}\n" "$hop_count" "$ip" "$rdns" "$country" "$org"
    fi
done
