# ai-skills

Skills compartidas entre **Claude Code** (`~/.claude/skills/`) y
**Antigravity** (`~/.gemini/config/skills/`). Ambas IAs leen el mismo formato
`SKILL.md`, así que esta carpeta es la fuente única de verdad y cada skill se
enlaza por symlink a las dos.

## Uso

```bash
# clonar como fuente
git clone git@github.com:alan196/ai-skills.git ~/.ai-skills

# enlazar todas las skills a Claude Code y Antigravity
bash ~/.ai-skills/link.sh
```

## Crear una skill nueva

1. `~/.ai-skills/<nombre>/SKILL.md` (frontmatter `name` + `description`).
2. `bash ~/.ai-skills/link.sh` — crea symlinks nuevos y limpia los rotos.

Nunca escribir directo en `~/.claude/skills/` ni `~/.gemini/config/skills/`:
esas rutas son solo symlinks a esta carpeta.
