#!/bin/bash
# install.sh - Configura el entorno y crea el lanzador de macOS

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$REPO_DIR/bin"
APP_NAME="LogicalUnplug.app"
DESKTOP_PATH="$HOME/Desktop/$APP_NAME"

echo "🚀 Configurando Logical Unplug..."

# 1. Dar permisos a los scripts
chmod +x "$BIN_DIR/toggle_monitor.sh"
chmod +x "$BIN_DIR/reenable-displays.py"

# 2. Crear la App con osacompile
echo "🍎 Creando lanzador en el escritorio..."
osacompile -o "$DESKTOP_PATH" -e "do shell script "$BIN_DIR/toggle_monitor.sh""

if [ -d "$DESKTOP_PATH" ]; then
    echo "✅ ¡Listo! 'LogicalUnplug.app' ha sido creada en tu escritorio."
    echo "💡 Puedes arrastrarla a tu Dock ahora."
else
    echo "❌ Error al crear la aplicación."
fi
