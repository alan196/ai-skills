#!/bin/bash
# Uso: desde la raíz del repo del cliente
# bash ~/.claude/skills/document-odoo-module/document-all-modules.sh

REPO_ROOT=$(pwd)

for dir in */; do
  if [ -f "$dir/__manifest__.py" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Documentando módulo: $dir"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cd "$REPO_ROOT/$dir"
    claude -p "/document-odoo-module" --permission-mode acceptEdits
    cd "$REPO_ROOT"
  fi
done

echo "✅ Documentación completa del repositorio generada."

