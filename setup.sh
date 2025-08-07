#!/bin/bash

echo "[+] Starting setup..."

# Start Network Manager
sudo systemctl start NetworkManager

# Install dependencies
echo "[+] Installing hostapd, dnsmasq, php, xterm, python3-tk, mdk3, libxml2-utils, jq..."
sudo apt install -y hostapd dnsmasq php xterm python3-tk mdk3 libxml2-utils jq

# Install pip3 if not found
if ! command -v pip3 &> /dev/null; then
    echo "[+] pip3 not found, installing it now..."
    sudo apt install -y python3-pip
fi

# Install Python libraries
echo "[+] Installing Python libraries..."
pip3 install requests PyQt5 rich --break-system-packages

# Make rc scripts executable and move to /usr/local/bin
echo "[+] Setting up rc scripts..."
SCRIPTS=("whonet.sh" "trrt.sh" "whonetp.sh")
for script in "${SCRIPTS[@]}"; do
    if [[ -f "rc/$script" ]]; then
        chmod +x "rc/$script"
        sudo cp "rc/$script" /usr/local/bin/${script%.sh}
        echo "[✓] Installed ${script%.sh} command."
    else
        echo "[!] rc/$script not found. Skipping..."
    fi
done

# Make main blacknet.sh executable and copy to /usr/local/bin
if [[ -f "blacknet.sh" ]]; then
    chmod +x blacknet.sh
    sudo cp blacknet.sh /usr/local/bin/blacknet
    echo "[✓] Installed blacknet command. Run it anywhere using 'blacknet'."
else
    echo "[!] blacknet.sh not found. Skipping..."
fi

echo "[✓] All dependencies and scripts installed successfully!"
echo "[+] You can now use: blacknet, trrt, whonet, whonetp from anywhere."
