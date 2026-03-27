import time
import os
import sys

# Definimos los números en ASCII art y los dos puntos
NUMBERS = {
    '0': ["  ___  ", " / _ \\ ", "| | | |", "| | | |", "| |_| |", " \\___/ "],
    '1': [" __ ", "/_ |", " | |", " | |", " | |", " |_|"],
    '2': [" ___  ", "|__ \\ ", "   ) |", "  / / ", " / /_ ", "|____|"],
    '3': [" ____  ", "|___ \\ ", "  __) |", " |__ < ", " ___) |", "|____/ "],
    '4': [" _  _   ", "| || |  ", "| || |_ ", "|__   _|", "   | |  ", "   |_|  "],
    '5': [" _____ ", "| ____|", "| |__  ", "|___ \\ ", " ___) |", "|____/ "],
    '6': ["   __  ", "  / /  ", " / /_  ", "| '_ \\ ", "| (_) |", " \\___/ "],
    '7': [" ______ ", "|____  |", "    / / ", "   / /  ", "  / /   ", " /_/    "],
    '8': ["  ___  ", " / _ \\ ", "| (_) |", " > _ < ", "| (_) |", " \\___/ "],
    '9': ["  ___  ", " / _ \\ ", "| (_) |", " \\__, |", "   / / ", "  /_/  "],
    ':': ["     ", "  _  ", " (_) ", " (_) ", "  _  ", "     "]
}

# Códigos de escape ANSI para colores
COLORS = {
    "GREEN": "\033[32m",
    "YELLOW": "\033[33m",
    "RED": "\033[31m",
    "BLINK_RED": "\033[31;5m",
    "RESET": "\033[0m"
}

def get_terminal_size():
    """Obtiene el tamaño actual de la terminal para poder centrar el reloj."""
    try:
        columns, rows = os.get_terminal_size(0)
    except OSError:
        columns, rows = 80, 24
    return columns, rows

def generate_large_number_str(number_str):
    """Convierte la cadena de tiempo en arte ASCII."""
    lines = [""] * 6
    for digit in number_str:
        if digit in NUMBERS:
            for i in range(6):
                lines[i] += NUMBERS[digit][i] + "  "
    return lines

def print_centered(lines, color_code="", progress_text=""):
    """Dibuja el reloj y la barra de progreso centrados en la pantalla, evitando parpadeos."""
    columns, rows = get_terminal_size()
    
    # Calcular relleno (padding) en el eje Y para centrar verticalmente
    total_height = len(lines) + 2  # +2 para la barra de progreso
    pad_y = max(0, (rows - total_height) // 2)
    
    # Mover el cursor arriba a la izquierda (evita el parpadeo de usar `clear`)
    sys.stdout.write("\033[H")
    
    # Rellenar con espacio vacío vertical
    for _ in range(pad_y):
        sys.stdout.write(" " * columns + "\n")
        
    # Imprimir números gigantes con el color correspondiente
    for line in lines:
        pad_x = max(0, (columns - len(line)) // 2)
        sys.stdout.write(" " * pad_x + f"{color_code}{line}{COLORS['RESET']}" + " " * pad_x + "\n")
        
    # Imprimir texto de debajo (barra de progreso o mensajes finales)
    if progress_text:
        sys.stdout.write("\n")
        pad_x = max(0, (columns - len(progress_text)) // 2)
        sys.stdout.write(" " * pad_x + progress_text + " " * pad_x + "\n")
    
    # Limpiar el rastro de lineas que hayan quedado debajo
    sys.stdout.write("\033[J")
    sys.stdout.flush()

def get_color(remaining, total):
    """Devuelve un color que avisa del progreso (Verde -> Amarillo -> Rojo)."""
    if total <= 0: return COLORS["RED"]
    ratio = remaining / total
    if ratio > 0.5:
        return COLORS["GREEN"]
    elif ratio > 0.2:
        return COLORS["YELLOW"]
    else:
        return COLORS["RED"]

def create_progress_bar(remaining, total, width=40):
    """Crea una barra de progreso que se va vaciando."""
    if total <= 0: return ""
    ratio = remaining / total
    filled = int(width * ratio)
    bar = "█" * filled + "░" * (width - filled)
    return f"[{bar}]"

def countdown(total_seconds):
    # Limpiar pantalla y ocultar cursor al inicio para dar un toque más profesional
    sys.stdout.write("\033[2J\033[?25l")
    sys.stdout.flush()
    
    seconds = total_seconds
    try:
        while seconds >= 0:
            color = get_color(seconds, total_seconds)
            mins, secs = divmod(seconds, 60)
            time_str = f"{mins:02d}:{secs:02d}"
            
            lines = generate_large_number_str(time_str)
            prog_bar = create_progress_bar(seconds, total_seconds)
            
            print_centered(lines, color, prog_bar)
            time.sleep(1)
            seconds -= 1
            
        # Animación de flash (Parpadeo rápido)
        lines = generate_large_number_str("00:00")
        for i in range(10):
            color = COLORS["BLINK_RED"] if i % 2 == 0 else ""
            print_centered(lines, color, "¡TIEMPO TERMINADO!")
            time.sleep(0.5)
            
        print("\n\a")  # Timbre predeterminado de la terminal (Bell)
        
    except KeyboardInterrupt:
        # Si cerramos con Ctrl+C que no se rompa la terminal
        pass
    finally:
        # Traer de vuelta el cursor!!
        sys.stdout.write("\033[?25h")
        sys.stdout.write("\033[2J\033[H")
        sys.stdout.flush()
        print("Fin de la cuenta atrás.")

def parse_time(user_input):
    """Soporte para formato 'MM:SS' o solo 'Minutos'."""
    user_input = user_input.strip()
    if ":" in user_input:
        parts = user_input.split(":")
        if len(parts) == 2:
            return int(parts[0]) * 60 + int(parts[1])
    else:
        return int(float(user_input) * 60)
    return -1

if __name__ == "__main__":
    while True:
        try:
            print("\033[2J\033[H", end="") # Limpiar todo al arrancar
            print("=== Reloj de Cuenta Atrás ===")
            print("Puedes poner minutos enteros ('5', '2.5') o minutos y segundos ('1:30')")
            time_input = input("\nIngresa el tiempo: ")
            
            total_seconds = parse_time(time_input)
            if total_seconds > 0:
                countdown(total_seconds)
                break
            else:
                print("\nError: El tiempo debe ser mayor a 0.")
                time.sleep(2)
        except ValueError:
            print("\nError: Por favor, usa un formato válido (como '5' o '0:45').")
            time.sleep(2)
