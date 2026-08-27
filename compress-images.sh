#!/usr/bin/env bash
#
# compress-images.sh — comprime jpg/png/gif/webp de la carpeta actual
# Ejecutar desde la carpeta que quieres comprimir.
#
# Detecta el gestor de paquetes (dnf/apt/pacman/zypper/brew), instala
# las dependencias que falten y sigue funcionando aunque alguna
# herramienta no se pueda instalar (simplemente salta ese formato).

set -uo pipefail

# ────────────────────────────────
# Config (se puede sobreescribir por variables de entorno)
# ────────────────────────────────
JPEG_QUALITY="${JPEG_QUALITY:-85}"
PNG_QUALITY="${PNG_QUALITY:-75-90}"
GIF_LOSSY="${GIF_LOSSY:-20}"
WEBP_QUALITY="${WEBP_QUALITY:-85}"

DIR="$(basename "$PWD")"
OUT="${DIR}_compressed"

# ────────────────────────────────
# Utilidades
# ────────────────────────────────
log()  { printf '%s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*" >&2; }
err()  { printf '❌ %s\n' "$*" >&2; }

human_size() {
    local bytes="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec --suffix=B "$bytes" 2>/dev/null || printf '%sB' "$bytes"
    else
        printf '%sB' "$bytes"
    fi
}

file_size() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || echo 0
}

# ────────────────────────────────
# Detección del gestor de paquetes e instalación de dependencias
# ────────────────────────────────
PKG_MANAGER=""
if command -v dnf >/dev/null 2>&1; then PKG_MANAGER="dnf"
elif command -v apt-get >/dev/null 2>&1; then PKG_MANAGER="apt"
elif command -v pacman >/dev/null 2>&1; then PKG_MANAGER="pacman"
elif command -v zypper >/dev/null 2>&1; then PKG_MANAGER="zypper"
elif command -v brew >/dev/null 2>&1; then PKG_MANAGER="brew"
fi

# tool -> paquete por gestor (usando "|" como separador: dnf|apt|pacman|zypper|brew)
declare -A PKG_MAP=(
    [jpegoptim]="jpegoptim|jpegoptim|jpegoptim|jpegoptim|jpegoptim"
    [pngquant]="pngquant|pngquant|pngquant|pngquant|pngquant"
    [optipng]="optipng|optipng|optipng|optipng|optipng"
    [gifsicle]="gifsicle|gifsicle|gifsicle|gifsicle|gifsicle"
    [cwebp]="libwebp-tools|webp|libwebp|libwebp-tools|webp"
)

pkg_for_tool() {
    local tool="$1" spec idx
    spec="${PKG_MAP[$tool]}"
    case "$PKG_MANAGER" in
        dnf)    idx=1 ;;
        apt)    idx=2 ;;
        pacman) idx=3 ;;
        zypper) idx=4 ;;
        brew)   idx=5 ;;
        *)      idx=1 ;;
    esac
    cut -d'|' -f"$idx" <<< "$spec"
}

install_tool() {
    local tool="$1" pkg
    pkg="$(pkg_for_tool "$tool")"

    if [ -z "$PKG_MANAGER" ]; then
        warn "No se detectó un gestor de paquetes soportado (dnf/apt/pacman/zypper/brew)."
        warn "Instala '$pkg' manualmente para poder procesar ${tool#*.} ."
        return 1
    fi

    log "→ Instalando '$pkg' con $PKG_MANAGER (necesario para $tool)..."
    case "$PKG_MANAGER" in
        dnf)
            sudo dnf install -y "$pkg" ;;
        apt)
            sudo apt-get update -qq && sudo apt-get install -y "$pkg" ;;
        pacman)
            sudo pacman -Sy --noconfirm "$pkg" ;;
        zypper)
            sudo zypper --non-interactive install "$pkg" ;;
        brew)
            brew install "$pkg" ;;
    esac
}

ensure_tool() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi
    if ! install_tool "$tool"; then
        return 1
    fi
    if ! command -v "$tool" >/dev/null 2>&1; then
        err "No se pudo instalar '$tool'. Los archivos de ese tipo se copiarán sin comprimir."
        return 1
    fi
    return 0
}

# ────────────────────────────────
# Comprobación de qué formatos hay en la carpeta, para no instalar
# de más cosas que no vamos a usar
# ────────────────────────────────
shopt -s nullglob nocaseglob
all_files=(*.jpg *.jpeg *.png *.gif *.webp)
shopt -u nocaseglob

if [ ${#all_files[@]} -eq 0 ]; then
    err "No se encontraron imágenes (jpg/jpeg/png/gif/webp) en $PWD"
    exit 1
fi

HAS_JPG=false HAS_PNG=false HAS_GIF=false HAS_WEBP=false
for f in "${all_files[@]}"; do
    case "${f,,}" in
        *.jpg|*.jpeg) HAS_JPG=true ;;
        *.png)        HAS_PNG=true ;;
        *.gif)        HAS_GIF=true ;;
        *.webp)       HAS_WEBP=true ;;
    esac
done

$HAS_JPG  && { ensure_tool jpegoptim || true; }
$HAS_PNG  && { ensure_tool pngquant  || true; ensure_tool optipng || true; }
$HAS_GIF  && { ensure_tool gifsicle  || true; }
$HAS_WEBP && { ensure_tool cwebp     || true; }

# ────────────────────────────────
# Copiar a carpeta de salida
# ────────────────────────────────
mkdir -p "$OUT" || { err "No se pudo crear '$OUT'"; exit 1; }

declare -A ORIG_SIZE
for f in "${all_files[@]}"; do
    if ! cp -- "$f" "$OUT/$f"; then
        warn "No se pudo copiar '$f', se omite."
        continue
    fi
    ORIG_SIZE["$f"]="$(file_size "$f")"
done

log ""
log "Comprimiendo en $OUT/ ..."

FAILED=()
for f in "${!ORIG_SIZE[@]}"; do
    target="$OUT/$f"
    lower="${f,,}"
    case "$lower" in
        *.jpg|*.jpeg)
            if command -v jpegoptim >/dev/null 2>&1; then
                jpegoptim --strip-all --all-progressive -m "$JPEG_QUALITY" "$target" \
                    || { warn "Falló jpegoptim en '$f'"; FAILED+=("$f"); }
            fi
            ;;
        *.png)
            if command -v pngquant >/dev/null 2>&1; then
                pngquant --quality="$PNG_QUALITY" --force --ext .png "$target" \
                    || warn "pngquant no pudo reducir '$f' (se sigue con optipng)"
            fi
            if command -v optipng >/dev/null 2>&1; then
                optipng -o2 -strip all -quiet "$target" \
                    || { warn "Falló optipng en '$f'"; FAILED+=("$f"); }
            fi
            ;;
        *.gif)
            if command -v gifsicle >/dev/null 2>&1; then
                gifsicle --optimize=3 --lossy="$GIF_LOSSY" --output "$target" "$target" \
                    || { warn "Falló gifsicle en '$f'"; FAILED+=("$f"); }
            fi
            ;;
        *.webp)
            if command -v cwebp >/dev/null 2>&1; then
                if cwebp -q "$WEBP_QUALITY" -m 6 -o "$target.tmp" "$target" 2>/dev/null; then
                    mv -f "$target.tmp" "$target"
                else
                    warn "Falló cwebp en '$f'"
                    FAILED+=("$f")
                    rm -f "$target.tmp"
                fi
            fi
            ;;
    esac
done

# ────────────────────────────────
# Resultados
# ────────────────────────────────
log ""
log "Listo. Comparación de tamaños:"
printf "%-40s %12s %12s %8s\n" "Archivo" "Antes" "Después" "Ahorro"

total_before=0
total_after=0
for f in "${!ORIG_SIZE[@]}"; do
    orig_size="${ORIG_SIZE[$f]}"
    new_size="$(file_size "$OUT/$f")"
    total_before=$((total_before + orig_size))
    total_after=$((total_after + new_size))

    if [ "$orig_size" -gt 0 ]; then
        pct=$(( (orig_size - new_size) * 100 / orig_size ))
    else
        pct=0
    fi
    printf "%-40s %12s %12s %7s%%\n" \
        "$f" "$(human_size "$orig_size")" "$(human_size "$new_size")" "$pct"
done

log ""
if [ "$total_before" -gt 0 ]; then
    total_pct=$(( (total_before - total_after) * 100 / total_before ))
else
    total_pct=0
fi
log "Total: $(human_size "$total_before") → $(human_size "$total_after")  (ahorro: ${total_pct}%)"

if [ ${#FAILED[@]} -gt 0 ]; then
    log ""
    warn "Estos archivos tuvieron problemas y quedaron sin comprimir del todo:"
    for f in "${FAILED[@]}"; do
        warn "  - $f"
    done
fi

exit 0
