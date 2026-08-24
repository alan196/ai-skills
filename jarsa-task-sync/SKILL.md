---
name: jarsa-task-sync
description: Sync Claude Code work with Odoo tasks at Jarsa. Trigger whenever the user
  assigns development work for a client (Promovago, MTNMX, Salmart, Starka, Grupo Versa,
  Chowdhury, etc.), mentions a task id, starts a branch/PR for client work, or finishes
  a coding session that should log hours.
---

# Jarsa Task Sync

Rules when working on any client development (requires the `jarsa-odoo` MCP
server; if its tools are not available, tell the user to connect it and skip
silently):

1. **On task start:** call `jarsa-odoo:find_or_create_task` with:
   - `external_ref`: `claude-code:<client>:<branch-name>` (branch naming per
     repo rules).
   - project: resolve with `find_project_for_client(partner_name=<client>)`;
     if multiple candidates, ASK the user which project.
   - `name`: short imperative title of the work; `description`: the user's
     request plus the implementation plan, in HTML (`<p>`, `<ul>`, `<b>`,
     `<code>`…) or plain text — NEVER markdown, it is stored verbatim. Same
     rule for every `post_task_message` body.
   - **Language: ALWAYS Spanish** for everything written to Odoo — task
     title, description, chatter notes and timesheet descriptions. (Only
     Git/GitHub/GitLab artifacts — commits, PR/MR titles and bodies — stay
     in English.)
   - If the tool returns `candidates`, show them and ask the user whether one
     of those is the task (then `update_task` setting `external_ref`) or a
     new one is needed (`strict=true`).
   - If the task already existed, post an internal note with
     `post_task_message`: "Work started via Claude Code on branch <branch>".
2. **During work:** if scope changes materially, `update_task` the
   description; if blocked, `move_task_stage(mark_kanban_state='blocked',
   reason=...)`.
3. **On MR creation:** the MR title MUST include `task#<odoo_task_id>` (repo
   rule); post the MR URL to the task chatter as an internal note with
   `post_task_message`.
4. **On completion:** ask the user how many hours to log (propose an estimate
   from the session), then `log_timesheet(task_id, hours,
   description=<summary of what was done>)` and `move_task_stage` to the
   review/done stage the user confirms.
5. **On closing a task:** a task counts as closed only when BOTH: stage is
   "Hecho" (`move_task_stage`) AND `state = '1_done'` (set with
   `update_records(model='project.task', ids=[<id>], values={'state':
   '1_done'})`; moving the stage alone does not change `state`). Note the
   value is `1_done`, not `01_done`.
6. Never notify followers (`notify_followers` stays false) unless the user
   asks. Use `dry_run=true` first for stage moves and bulk changes, and apply
   only after the user confirms.
7. **NUNCA enviar un mensaje sin autorización previa — regla inviolable.**
   Aplica a CUALQUIER mensaje que salga hacia otra persona: chatter de una
   tarea (`post_task_message`, sea `comment` o `note`), correo, comentario en
   un PR/MR, mensaje en Slack/WhatsApp, respuesta a un cliente. También
   aplica cuando el usuario dice "manda el mensaje", "notifícale", "avísale"
   o "cámbialo y envíalo": esa instrucción autoriza a REDACTAR, nunca a
   enviar.
   El flujo es siempre: (1) escribir la propuesta completa del mensaje en la
   respuesta al usuario, tal cual se va a enviar; (2) esperar a que el
   usuario la revise y la autorice explícitamente; (3) solo entonces,
   enviarla. Si el usuario pide cambios, se repite el ciclo con la nueva
   propuesta.
   Nunca asumir que una autorización anterior cubre un mensaje nuevo, ni que
   "ya me lo habías aprobado" aplica a una versión modificada del texto.
