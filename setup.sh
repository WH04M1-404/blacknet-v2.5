#!/bin/bash

echo "[+] Starting setup..."


sudo apt update


echo "[+] Installing hostapd, dnsmasq, php, xterm, python3-tk..."
sudo apt install -y hostapd dnsmasq php xterm python3-tk mdk3


if ! command -v pip3 &> /dev/null; then
    echo "[+] pip3 not found, installing it now..."
    sudo apt install -y python3-pip
fi


echo "[+] Installing Python libraries..."
pip3 install requests --break-system-packages

echo "[✓] All dependencies installed successfully!"
