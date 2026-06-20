---
name: shared-skills
description: Reglas para crear/editar skills compartidas entre Claude Code y Antigravity. ACTIVAR siempre que se vaya a crear, editar o borrar una skill (SKILL.md), o cuando el usuario hable de "skill nueva", "compartir skill" o "skills entre las dos IA".
---

# Skills compartidas entre Claude Code y Antigravity

Las dos IAs leen el mismo formato `SKILL.md`. La fuente única de verdad es
`~/.ai-skills/`; cada skill se enlaza por symlink a ambas:

- Claude Code → `~/.claude/skills/<nombre>`
- Antigravity → `~/.gemini/config/skills/<nombre>`

## Al crear o borrar una skill — OBLIGATORIO

1. Crear/editar la carpeta SIEMPRE dentro de `~/.ai-skills/<nombre>/SKILL.md`.
   NUNCA escribir directo en `~/.claude/skills/` ni en `~/.gemini/config/skills/`
   (esas rutas son solo symlinks).
2. Correr el enlazador para propagar a ambas IAs:

   ```bash
   bash ~/.ai-skills/link.sh
   ```

   Eso crea los symlinks de las skills nuevas y limpia los rotos de las borradas.
3. Confirmar que el symlink quedó en las dos rutas.

## Formato del SKILL.md

Frontmatter mínimo (idéntico en ambas IAs):

```markdown
---
name: <kebab-case, igual al nombre de la carpeta>
description: <cuándo activar la skill — frase clara de disparo>
---
```
