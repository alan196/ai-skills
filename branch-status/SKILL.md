---
name: branch-status
description: Estado del branch antes de tocar código. ACTIVAR SIEMPRE antes de empezar cualquier cambio en un repo git (editar, crear PR, commitear).
---

# Estado del branch antes de comenzar cualquier cambio

Si al inicio de la sesión ya hay una línea `branch-status: ...` inyectada
(hook SessionStart de Claude Code), usarla directamente. Si no existe o ya
pasó tiempo/cambió de repo, correr UNA sola vez (sin comandos git adicionales):

```bash
bash ~/.ai-skills/branch-status/check.sh
```

Interpretar la línea de salida:

- `behind=0 wip=no` y sin trabajo sin mergear → continuar, no correr nada más.
- `behind>0` → actualizar/rebasear desde el remoto antes de empezar.
- `wip=si`, o branch de feature con `merged_en_*=no` → PREGUNTAR qué hacer
  (continuar ahí, ramificar, stash) ANTES de cualquier cambio.
- PR nuevo → crear SIEMPRE un branch nuevo desde la base actualizada del
  remoto destino (p.ej. `odoo/17.0` para PRs a Odoo).

Regla inviolable de remotos (repos Jarsa): los branches de trabajo se pushean
SOLO a `jarsa-dev` (Jarsa-dev/*); en los remotos `jarsa` (Jarsa/*) únicamente
viven los branches estables por versión (ej. `17.0`). NUNCA pushear un branch
de trabajo a `jarsa`.
