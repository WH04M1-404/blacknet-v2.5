import tkinter as tk
from tkinter import messagebox, filedialog, ttk
import random
import string
import time
import threading

user_data = {}
window_geometry = None

def generate_passwords(base_words, count, min_len, max_len, use_symbols):
    symbols = '!@#$%^&*()_+-=' if use_symbols else ''
    all_chars = string.ascii_letters + string.digits + symbols

    passwords = set()
    while len(passwords) < count:
        base = random.choice(base_words).replace('','')
        extra_len = random.randint(min_len - len(base), max_len - len(base))
        extra = ''.join(random.choices(all_chars, k=max(0, extra_len)))
        password = base + extra
        if min_len <= len(password) <= max_len:
            passwords.add(password)
    return list(passwords)

def main_info_page():
    def next_page():
        entries_keys = [
            "Full Name", "Last Name", "Birth Date", "Partner Name",
            "Pet Name", "Favorite Artist", "Mother's Name", "Hobby",
            "Interest", "Custom Info"
        ]
        for key, entry in zip(entries_keys, entries):
            val = entry.get().strip()
            user_data[key] = val if val else 'n'
        global window_geometry
        window_geometry = window.geometry()
        window.destroy()
        config_page()

    window = tk.Tk()
    window.title("Wordlist Generator - Target Info")
    window.configure(bg='black')
    if window_geometry:
        window.geometry(window_geometry)

    tk.Label(window, text="BL4CK lIST", font=('Courier', 16, 'bold'), fg='red', bg='black').pack(pady=10)

    labels = [
        "Full Name", "Last Name", "Birth Date (DDMMYYYY)", "Partner Name",
        "Pet Name", "Favorite Artist", "Mother's Name", "Hobby",
        "Interest", "Custom Info (optional)"
    ]
    global entries
    entries = []
    for label in labels:
        tk.Label(window, text=label, fg='white', bg='black').pack()
        entry = tk.Entry(window, width=40, bg='gray20', fg='white')
        entry.pack()
        entries.append(entry)

    tk.Button(window, text="Next", command=next_page, bg='red', fg='black').pack(pady=20)
    window.mainloop()

def config_page():
    def back():
        window.destroy()
        main_info_page()

    def next_page():
        try:
            user_data['count'] = int(entry_count.get())
            user_data['min_len'] = int(entry_min.get())
            user_data['max_len'] = int(entry_max.get())
            user_data['use_symbols'] = var_symbols.get()
            user_data['save_path'] = filedialog.asksaveasfilename(defaultextension=".txt")
            if not user_data['save_path']:
                messagebox.showwarning("Path Required", "You must select a save path.")
                return
            global window_geometry
            window_geometry = window.geometry()
            window.destroy()
            final_page()
        except ValueError:
            messagebox.showerror("Input Error", "Please enter valid numbers.")

    window = tk.Tk()
    window.title("Wordlist Generator - Configuration")
    window.configure(bg='black')
    if window_geometry:
        window.geometry(window_geometry)

    tk.Label(window, text="BL4CK LIST", font=('Courier', 16, 'bold'), fg='red', bg='black').pack(pady=10)

    tk.Label(window, text="How many passwords to generate?", fg='white', bg='black').pack()
    entry_count = tk.Entry(window, bg='gray20', fg='white')
    entry_count.pack()

    tk.Label(window, text="Minimum password length:", fg='white', bg='black').pack()
    entry_min = tk.Entry(window, bg='gray20', fg='white')
    entry_min.pack()

    tk.Label(window, text="Maximum password length:", fg='white', bg='black').pack()
    entry_max = tk.Entry(window, bg='gray20', fg='white')
    entry_max.pack()

    var_symbols = tk.BooleanVar()
    tk.Checkbutton(window, text="Include Symbols", variable=var_symbols, fg='white', bg='black', selectcolor='black').pack(pady=10)

    tk.Button(window, text="Back", command=back, bg='gray', fg='white').pack(side='left', padx=40, pady=20)
    tk.Button(window, text="Next", command=next_page, bg='red', fg='black').pack(side='right', padx=40, pady=20)
    window.mainloop()

def final_page():
    def generate_and_display():
        base_words = [v for v in user_data.values() if isinstance(v, str) and v != 'n']

        status_label.config(text="BL4CK LIST generating your passwords right now!", fg='red')
        status_label.update()
        time.sleep(10)

        result = generate_passwords(base_words, user_data['count'], user_data['min_len'], user_data['max_len'], user_data['use_symbols'])
        with open(user_data['save_path'], 'w') as f:
            for pw in result:
                f.write(pw + '\n')

        status_label.config(text="\n[+] Done! Generated Passwords:", fg='green')
        for pw in result:
            color = 'green' if random.random() > 0.5 else 'red'
            text_area.insert(tk.END, pw + "\n", color)

    window = tk.Tk()
    window.title("Wordlist Generator - Start")
    window.configure(bg='black')
    if window_geometry:
        window.geometry(window_geometry)

    tk.Label(window, text="BL4CK LIST", font=('Courier', 16, 'bold'), fg='red', bg='black').pack(pady=10)

    status_label = tk.Label(window, text="", font=('Courier', 12), fg='white', bg='black')
    status_label.pack(pady=10)

    text_area = tk.Text(window, bg='black', fg='white', insertbackground='white')
    text_area.tag_config('red', foreground='red')
    text_area.tag_config('green', foreground='green')
    text_area.pack(expand=True, fill='both')

    start_button = tk.Button(window, text="START", command=lambda: threading.Thread(target=generate_and_display).start(), bg='red', fg='black', font=('Courier', 14))
    start_button.pack(pady=10)

    window.mainloop()

main_info_page()
