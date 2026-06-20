#!/usr/bin/env bash
# Enlaza todas las skills de ~/.ai-skills a Claude Code y Antigravity.
# Correr tras crear/borrar una skill: bash ~/.ai-skills/link.sh
set -e
SRC=~/.ai-skills
CLAUDE=~/.claude/skills
GEMINI=~/.gemini/config/skills
mkdir -p "$CLAUDE" "$GEMINI"

# crear/actualizar symlinks de cada skill (carpetas, ignora link.sh)
for d in "$SRC"/*/; do
  n=$(basename "$d")
  ln -sfn "$d" "$CLAUDE/$n"
  ln -sfn "$d" "$GEMINI/$n"
  echo "linked: $n"
done

# limpiar symlinks rotos (skills borradas en la fuente)
for dir in "$CLAUDE" "$GEMINI"; do
  for l in "$dir"/*; do
    [ -L "$l" ] && [ ! -e "$l" ] && rm "$l" && echo "removed broken: $l"
  done
done
