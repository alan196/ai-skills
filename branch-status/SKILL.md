---
name: branch-status
description: Estado del branch antes de tocar código. ACTIVAR SIEMPRE antes de empezar cualquier cambio en un repo git (editar, crear PR, commitear), para asegurar que el branch esté actualizado y no haya trabajo sin mergear.
---

# Estado del branch antes de comenzar cualquier cambio

SIEMPRE, antes de tocar código en un repo git:

1. Asegurar que el branch actual esté actualizado con su remoto (`git fetch` +
   comparar ahead/behind). Si está atrasado, actualizar/rebasear desde el remoto
   correcto antes de empezar.
2. Si el branch NO es de producción (distinto de `production`/`main`/`17.0`…),
   revisar si ya se hizo push y si está mezclado (merged) en el destino.
3. Si el branch tiene WIP sin commitear o trabajo sin mergear, PREGUNTAR qué
   hacer (continuar ahí, ramificar, hacer stash…) ANTES de cualquier cambio.
4. Para un PR nuevo, crear SIEMPRE un branch nuevo desde la base actualizada del
   remoto destino (p.ej. `odoo/17.0` para PRs a Odoo).
