#!/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# GIPOCM
my_ip=$(hostname -I | awk '{print $1}')
subnet=$(echo $my_ip | awk -F. '{print $1"."$2"."$3}')

echo -e "${BLUE}Your IP: $my_ip${RESET}"
echo -e "${BLUE}Subnet detected: $subnet.0/24${RESET}"
echo -e "${YELLOW}Starting scan...${RESET}"
echo -e "-------------------------------------------"

for i in {1..255}; do
    (
        ip="$subnet.$i"
        ping -c 1 -W 0.3 $ip &> /dev/null
        if [ $? -eq 0 ]; then
            mac=$(arp -n $ip | grep -oE "([0-9a-f]{2}:){5}[0-9a-f]{2}" | head -n 1)
            if [ -z "$mac" ]; then
                mac="N/A"
            fi
            echo -e "${GREEN}[+] $ip is alive ${RESET}| ${YELLOW}MAC: $mac${RESET}"
        fi
    ) &
done
wait

echo -e "${BLUE}-------------------------------------------${RESET}"
echo -e "${GREEN}Scan completed.${RESET}"
