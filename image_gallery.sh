#!/bin/bash

# Uso del script
# ./image_gallery.sh /ruta/a/carpeta/con/imagenes

# Constantes
gallery_dir_name="gallery"
thumb_width=240
big_width=800

# Verificar la cantidad de argumentos
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/folder/that/contains/images"
  exit 1
fi

# Ruta del directorio de imágenes
path="$1"

# Verificar la existencia del directorio
if [ ! -d "$path" ]; then
  echo "Error: The folder $path was not found."
  exit 1
fi

# Mensaje de inicio
echo -e "\n========================================"
echo "     Image Gallery Script v1.6"
echo "========================================"
echo "Processing images in: $path"
echo "========================================"

# Función para redimensionar imágenes
resize_image() {
  img_file="$1"
  width="$2"
  destination_dir="$3"
  img_file_destination="$destination_dir/$(basename "$img_file")"
  
  # Verificar la existencia de la herramienta 'convert'
  if ! command -v convert &> /dev/null; then
    echo "Error: 'convert' command not found. Please install ImageMagick."
    exit 1
  fi

  convert "$img_file" -auto-orient -resize "$width" "$img_file_destination"
}

# Función para crear directorios de la galería
create_gallery_directories() {
  for dir in "original" "thumb" "big"; do
    if [ ! -d "$path/$gallery_dir_name/$dir" ]; then
      mkdir -p "$path/$gallery_dir_name/$dir"
      echo "Created directory: $path/$gallery_dir_name/$dir"
    fi
  done
}

# Procesamiento de imágenes
process_images() {
  image_files=("$path"/*.jpg "$path"/*.jpeg "$path"/*.png "$path"/*.gif)
  total_files=${#image_files[@]}
  processed_files=0

  for img_file in "${image_files[@]}"; do
    if [ -f "$img_file" ]; then
      create_gallery_directories
      file_name=$(basename "$img_file")

      # Copiar la imagen original a la carpeta 'original'
      cp "$img_file" "$path/$gallery_dir_name/original/$file_name"

      # Redimensionar para miniaturas
      resize_image "$img_file" "$thumb_width" "$path/$gallery_dir_name/thumb"

      # Redimensionar para imágenes grandes
      resize_image "$img_file" "$big_width" "$path/$gallery_dir_name/big"

      # Incrementar el contador de archivos procesados
      ((processed_files++))

      # Mostrar el progreso en la terminal
      percentage=$((processed_files * 100 / total_files))
      echo -ne "Progress: $percentage%\r"
    fi
  done

  # Imprimir un mensaje de finalización
  echo -e "\nProcessing completed. $processed_files files processed out of $total_files."
}

# Generación del código HTML
generate_html() {
  html_file="$path/index.html"
  cat <<EOF >"$html_file"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Image Gallery</title>
  <style>
    body {
      font-family: 'Arial', sans-serif;
      margin: 20px;
      background-color: #f8f8f8;
    }

    h1 {
      text-align: center;
      color: #444;
      text-shadow: 1px 1px 1px #ccc;
    }

    .gallery {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 20px;
    }

    figure {
      margin: 10px;
      text-align: center;
      border: 1px solid #ddd;
      border-radius: 8px;
      background-color: #fff;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      transition: transform 0.3s ease-in-out;
      position: relative;
      overflow: hidden;
    }

    img {
      width: 100%;
      height: 250px; /* Altura fija para una apariencia uniforme */
      object-fit: cover; /* Ajuste del contenido */
      border-radius: 8px 8px 0 0;
      display: block;
      margin: 0 auto; /* Centrar la imagen en el contenedor */
      filter: grayscale(100%); /* Blanco y negro por defecto */
      transition: filter 0.3s ease-in-out;
    }

    img:hover {
      filter: grayscale(0%); /* Blanco y negro al pasar el cursor */
    }

    figcaption {
      margin-top: 10px;
      color: #666;
    }

    p {
      margin: 10px 0;
    }

    a {
      color: #3498db;
      text-decoration: none;
      transition: color 0.3s ease-in-out;
    }

    a:hover {
      color: #2980b9;
    }
  </style>
</head>
<body>
  <h1>Image Gallery</h1>
  <div class="gallery">
EOF

  for img_file in "${image_files[@]}"; do
    if [ -f "$img_file" ] && [ "$img_file" != "$html_file" ]; then
      img_file_name=$(basename "$img_file")
      cat <<EOF >>"$html_file"
    <figure class="polaroid">
      <a href='${gallery_dir_name}/big/${img_file_name}' target='_blank'>
        <img src='${gallery_dir_name}/thumb/${img_file_name}' alt='${img_file_name}' />
      </a>
      <figcaption>${img_file_name}</figcaption>
      <p>
        <a href='${gallery_dir_name}/original/${img_file_name}' target='_blank'>View in High Resolution</a>
      </p>
    </figure>
EOF
    fi
  done

  cat <<EOF >>"$html_file"
  </div>
</body>
</html>
EOF

  echo "HTML file generated: $html_file"
}


# Proceso principal
process_images
generate_html

