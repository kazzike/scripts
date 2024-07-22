import time
import os

# Definimos los números en ASCII art y los dos puntos
NUMBERS = {
    '0': [
        "  ___  ",
        " / _ \\ ",
        "| | | |",
        "| | | |",
        "| |_| |",
        " \\___/ "
    ],
    '1': [
        " __ ",
        "/_ |",
        " | |",
        " | |",
        " | |",
        " |_|"
    ],
    '2': [
        " ___  ",
        "|__ \\ ",
        "   ) |",
        "  / / ",
        " / /_ ",
        "|____|"
    ],
    '3': [
        " ____  ",
        "|___ \\ ",
        "  __) |",
        " |__ < ",
        " ___) |",
        "|____/ "
    ],
    '4': [
        " _  _   ",
        "| || |  ",
        "| || |_ ",
        "|__   _|",
        "   | |  ",
        "   |_|  "
    ],
    '5': [
        " _____ ",
        "| ____|",
        "| |__  ",
        "|___ \\ ",
        " ___) |",
        "|____/ "
    ],
    '6': [
        "   __  ",
        "  / /  ",
        " / /_  ",
        "| '_ \\ ",
        "| (_) |",
        " \\___/ "
    ],
    '7': [
        " ______ ",
        "|____  |",
        "    / / ",
        "   / /  ",
        "  / /   ",
        " /_/    "
    ],
    '8': [
        "  ___  ",
        " / _ \\ ",
        "| (_) |",
        " > _ < ",
        "| (_) |",
        " \\___/ "
    ],
    '9': [
        "  ___  ",
        " / _ \\ ",
        "| (_) |",
        " \\__, |",
        "   / / ",
        "  /_/  "
    ],
    ':': [
        "     ",
        "  _  ",
        " (_) ",
        " (_) ",
        "  _  ",
        "     "
    ]
}

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_large_number(number, color_code=""):
    lines = ["", "", "", "", "", ""]
    for digit in number:
        for i in range(6):
            lines[i] += NUMBERS[digit][i] + "  "
    for line in lines:
        print(f"{color_code}{line}\033[0m")

def countdown(minutes):
    seconds = minutes * 60
    while seconds >= 0:
        clear_screen()
        mins, secs = divmod(seconds, 60)
        time_str = f"{mins:02d}:{secs:02d}"
        print_large_number(time_str)
        time.sleep(1)
        seconds -= 1

    clear_screen()
    for _ in range(10):  # Hacer parpadear el texto por unos segundos
        print_large_number("00:00", "\033[31;5m")  # Rojo y parpadeando
        time.sleep(0.5)
        clear_screen()
        time.sleep(0.5)

    print("¡Tiempo terminado!")

if __name__ == "__main__":
    time_input = input("Ingrese el tiempo en minutos: ")
    try:
        countdown(int(time_input))
    except ValueError:
        print("Por favor, ingrese un número válido.")
