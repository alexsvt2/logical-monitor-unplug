#!/bin/bash
# mac-monitor-toggle - Script para alternar monitores externos en macOS
# Basado en displayplacer y CoreGraphics

# --- CONFIGURACIÓN ---
# Reemplaza con tu ID de monitor (usa `displayplacer list` para encontrarlo)
DEFAULT_MONITOR_ID="0A12BF33-51C0-4EDB-9451-CBA844E422E4"
TARGET_ID="${1:-$DEFAULT_MONITOR_ID}"

# Rutas absolutas (Homebrew y binarios locales)
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
DISPLAYPLACER="/opt/homebrew/bin/displayplacer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REENABLE_SCRIPT="$SCRIPT_DIR/reenable-displays.py"

# --- LÓGICA ---

# Función para detectar si el monitor está encendido
is_monitor_on() {
    $DISPLAYPLACER list 2>/dev/null | sed -n "/$1/,/Enabled:/p" | grep -q "Enabled: true"
}

# Acción de Toggle
if is_monitor_on "$TARGET_ID"; then
    echo "Monitor detectado ($TARGET_ID). Desactivando..."
    $DISPLAYPLACER "id:$TARGET_ID enabled:false" >/dev/null 2>&1
else
    echo "Monitor no detectado o apagado. Activando todas las pantallas..."
    # Ejecuta el script de Python que resetea las configuraciones de CoreGraphics
    if [ -f "$REENABLE_SCRIPT" ]; then
        python3 "$REENABLE_SCRIPT" >/dev/null 2>&1
    else
        # Fallback si el script de python no está en el mismo folder
        /Users/alexislopez/bin/reenable-displays >/dev/null 2>&1
    fi
fi

# Salida limpia para que AppleScript (la App) no muestre errores
exit 0
