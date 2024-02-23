import os
import re
from PIL import Image
from tqdm import tqdm
from datetime import datetime

def sanitize_filename(filename):
    # Eliminar caracteres especiales y espacios
    return re.sub(r'[^\w\s.-]', '', filename)

def compress_image(input_path, output_path, target_size_mb=4, quality=85):
    try:
        # Cargar la imagen utilizando Pillow
        img = Image.open(input_path)

        # Verificar el tamaño de la imagen
        original_size_mb = os.path.getsize(input_path) / (1024 * 1024)

        if original_size_mb > target_size_mb:
            # Comprimir solo si el tamaño supera los 4MB
            img.save(output_path, quality=quality)
            return True
        else:
            # No comprimir, simplemente renombrar
            os.rename(input_path, output_path)
            return False

    except Exception as e:
        print(f"Error processing {input_path}: {e}")
        return False

def rename_and_compress_images(folder_path):
    # Obtén el nombre del directorio base
    folder_name = os.path.basename(folder_path)

    # Obtén la lista de archivos de imagen en la carpeta
    image_files = [f for f in os.listdir(folder_path) if f.lower().endswith(('.jpg', '.jpeg', '.webp', '.png', '.gif', '.bmp'))]

    # Configurar la barra de progreso
    progress_bar = tqdm(image_files, desc="Processing", unit="image")

    processed_count = 0
    start_time = datetime.now()

    # Enumera, renombra y comprime cada archivo de imagen
    for idx, image_file in enumerate(progress_bar, start=1):
        base, ext = os.path.splitext(image_file)
        sanitized_name = sanitize_filename(base)
        new_name = f"{idx:02d}-{folder_name}{ext.lower()}"
        old_path = os.path.join(folder_path, image_file)
        new_path = os.path.join(folder_path, new_name)

        # Comprimir las imágenes para que tengan un peso máximo de 4MB
        if compress_image(old_path, new_path, target_size_mb=4, quality=85):
            processed_count += 1

        # Actualizar la barra de progreso
        progress_bar.set_postfix({"Processed": processed_count})

    end_time = datetime.now()
    elapsed_time = end_time - start_time

    print(f"\nRenaming and compressing images in '{folder_name}' complete.")
    print(f"\033[1;97mProcessed files: \033[1;37m{processed_count} \033[1;97min \033[1;37m{elapsed_time}")

# Identificar automáticamente el folder_path
folder_path = os.getcwd()
rename_and_compress_images(folder_path)
