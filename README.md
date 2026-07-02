# ai-skills

Skills compartidas entre **Claude Code** (`~/.claude/skills/`) y
**Antigravity** (`~/.gemini/config/skills/`). Ambas IAs leen el mismo formato
`SKILL.md`, así que esta carpeta es la fuente única de verdad y cada skill se
enlaza por symlink a las dos.

## Instalación (una línea)

```bash
git clone https://github.com/alan196/ai-skills.git ~/.ai-skills && bash ~/.ai-skills/link.sh
```

Eso clona la fuente y enlaza por symlink todas las skills a Claude Code y
Antigravity. Para actualizar después:

```bash
git -C ~/.ai-skills pull && bash ~/.ai-skills/link.sh
```

Si vas a contribuir, clona por SSH: `git clone git@github.com:alan196/ai-skills.git ~/.ai-skills`

## Crear una skill nueva

1. `~/.ai-skills/<nombre>/SKILL.md` (frontmatter `name` + `description`).
2. `bash ~/.ai-skills/link.sh` — crea symlinks nuevos y limpia los rotos.

Nunca escribir directo en `~/.claude/skills/` ni `~/.gemini/config/skills/`:
esas rutas son solo symlinks a esta carpeta.
