#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXECUTABLE="$REPO_DIR/dist/LogicalUnplug.app/Contents/MacOS/LogicalUnplug"
if [ ! -x "$EXECUTABLE" ]; then
  EXECUTABLE="$HOME/Applications/LogicalUnplug.app/Contents/MacOS/LogicalUnplug"
fi
if [ ! -x "$EXECUTABLE" ]; then
  printf 'Primero instala la app ejecutando: bash "%s/install.sh"\n' "$REPO_DIR" >&2
  exit 1
fi
if [ "$#" -eq 0 ]; then
  exec "$EXECUTABLE" --toggle
elif [[ "$1" != --* ]]; then
  exec "$EXECUTABLE" --toggle "$@"
else
  exec "$EXECUTABLE" "$@"
fi
