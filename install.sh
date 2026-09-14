#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$HOME/Applications/LogicalUnplug.app"
bash "$REPO_DIR/build.sh"
mkdir -p "$HOME/Applications"
if [ -e "$APP" ]; then
  BACKUP_DIR="$(mktemp -d "$HOME/Applications/LogicalUnplug-backup.XXXXXX")"
  ditto "$APP" "$BACKUP_DIR/LogicalUnplug.app"
  printf 'Versión anterior respaldada: %s\n' "$BACKUP_DIR"
fi
ditto "$REPO_DIR/dist/LogicalUnplug.app" "$APP"
printf 'Instalada: %s\nÁbrela desde Finder o arrástrala al Dock.\n' "$APP"
