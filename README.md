# Useful Scripts Collection

This directory contains a collection of utility scripts written in Python and Bash for various automation and productivity tasks.

## Scripts Overview

### 1. `Backup.py`
A python script that compresses a specified directory into a `.tar.gz` archive and uploads it to a remote server using `rsync`.

**Prerequisites:** 
- `rsync` installed on your system.
- Ensure you set `originPath`, `tmpDestinationPath`, `originLocal`, and `DestinationServer` variables inside the script before running it.

**Usage:**
```bash
python3 Backup.py
```

### 2. `ImageCompressor.py`
A script that scans the current directory for image files, compresses any image larger than 4MB, and renames them sequentially (e.g., `01-foldername.jpg`).

**Prerequisites:**
- `Pillow` and `tqdm` libraries. Install with `pip install Pillow tqdm`.

**Usage:**
Place the script in the directory containing the images you want to process and run:
```bash
python3 ImageCompressor.py
```

### 3. `contador.py`
A visual countdown timer for the terminal that displays remaining time in large ASCII art numbers and blinks red when the time is up.

**Usage:**
```bash
python3 contador.py
```
*The script will prompt you to enter the initial time in minutes.*

### 4. `image_gallery.sh`
A bash script that processes a directory of images to create a web-based gallery. It automatically generates `original`, `thumb` (240px), and `big` (800px) versions of the images, and creates an `index.html` file to display them in a neat, responsive grid.

**Prerequisites:**
- `ImageMagick` must be installed (for the `convert` command).

**Usage:**
```bash
./image_gallery.sh /path/to/folder/that/contains/images
```