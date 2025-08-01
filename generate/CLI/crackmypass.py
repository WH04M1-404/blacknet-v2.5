import random
import string
import os
import time


RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"


common_wifi_passwords = [
    "password123", "12345678", "123456789", "1234567890",
    "12345678#", "12345678##", "12345678$$",
    "87654321", "87654321#", "87654321$$",
    "adminadmin", "admin1234", "admin12345", "administrator",
    "11111111", "22222222", "33333333", "44444444",
    "55555555", "66666666", "77777777", "88888888", "99999999", "00000000",
    "11223344", "1122334455", "112233445566", "iloveyou123",
    "letmein123", "qwertyuiop", "passw0rd!", "abc123456",
    "superman123", "batman2024", "homewifi123", "securepass", "supersecure",
    "mypassword1", "yourpassword", "internet123", "wifipassword",
    "mywifi2024", "defaultpass", "welcomewifi", "network2024"
]


def print_banner():
    banner = f"""{RED}
╔════════════════════════════════════════════════════╗
║           C R A C K   M Y   P A S S                ║
╠════════════════════════════════════════════════════╣
║   ➤ wordlist generating tool for wifi              ║
║   ➤ Developed by: WH04M1                           ║
╚════════════════════════════════════════════════════╝
{RESET}"""
    print(banner)
    time.sleep(1)


def generate_password(length, use_symbols=True, keywords=None):
    base = ''
    if keywords:
        base = random.choice(keywords)
        remain = length - len(base)
        if remain < 1:
            return base[:length]
    else:
        remain = length

    chars = string.ascii_letters + string.digits
    if use_symbols:
        chars += "!@#$%^&*"

    suffix = ''.join(random.choice(chars) for _ in range(remain))
    return base + suffix

def main():
    print_banner()

    try:
        print(YELLOW + "[+] How many passwords to generate?" + RESET)
        num_passwords = int(input("> "))
        print(YELLOW + "[+] Select minimum length:" + RESET)
        min_length = int(input("> "))
        print(YELLOW + "[+] Select maximum length:" + RESET)
        max_length = int(input("> "))
        print(YELLOW + "[+] Select the saved document name (without extension):" + RESET)
        filename = input("> ")
        print(YELLOW + "[+] Select where to save the list (e.g., /home/user/Desktop):" + RESET)
        save_path = input("> ")
        print(YELLOW + "[+] Add common used passwords for wifi? (y/n):" + RESET)
        add_common = input("> ").lower()
        print(YELLOW + "[+] Include symbols in generated passwords? (y/n):" + RESET)
        use_symbols = input("> ").lower() == 'y'
        print(YELLOW + "[+] Do you want to add keywords to mix with the passwords? (y/n):" + RESET)
        use_keywords = input("> ").lower()

        keywords = []
        if use_keywords == 'y':
            print(YELLOW + "[+] Enter your keywords (comma-separated):" + RESET)
            user_input = input("> ")
            keywords = [word.strip() for word in user_input.split(",") if word.strip()]

        if not os.path.exists(save_path):
            os.makedirs(save_path)

        full_path = os.path.join(save_path, filename + ".txt")

        with open(full_path, "w") as f:
            if add_common == 'y':
                for pwd in common_wifi_passwords:
                    if len(pwd) >= 8:
                        f.write(pwd + "\n")

            for _ in range(num_passwords):
                length = random.randint(min_length, max_length)
                f.write(generate_password(length, use_symbols, keywords) + "\n")

        print(YELLOW + "\n[+] Please wait while we generate the wordlist..." + RESET)
        time.sleep(1)
        print(YELLOW + f"[+] Saved in {full_path}" + RESET)
        print(RED + "[-] Happy crack!!" + RESET)

    except Exception as e:
        print(RED + f"[!] Error: {e}" + RESET)

if __name__ == "__main__":
    main()
