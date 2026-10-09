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
   description=<summary of what was done>)`. Then PROPOSE (never do it
   unasked) the hand-off to internal testing:
   - Move the task to stage "Pruebas Internas" (`move_task_stage` with
     `dry_run=true` first, apply after the user confirms). If the user
     prefers another stage, use that one.
   - Notify the project manager: `project.project.user_id` of the task's
     project (read its `partner_id`). If the project has no manager or the
     manager is the user, say so and skip the notification. Draft a chatter
     message in Spanish, HTML, with: <b>Qué se hizo</b> (functional summary,
     branch and MR link), <b>Dónde probar</b> (staging/build URL and database,
     if any) and <b>Pasos para probar</b> (numbered `<ol>`: menu path, test
     data, action and expected result for each case, including the edge cases
     that were covered).
   - The message follows rule 7: show the full text and its destination, wait
     for explicit approval. Once approved, send it so ONLY the manager is
     notified (task followers may include the client): `call_method(
     model='project.task', method='message_post', ids=[<task_id>],
     kwargs={'body': <html>, 'body_is_html': True, 'message_type': 'comment',
     'subtype_xmlid': 'mail.mt_note', 'partner_ids': [<pm_partner_id>]})`.
     Do NOT use `post_task_message(notify_followers=true)` for this.
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
   **Cada petición de autorización lleva el texto completo en ese mismo
   mensaje.** Prohibido pedir "¿la publico?" o dejar "falta tu OK a la nota"
   en la lista de pendientes sin imprimir la nota íntegra justo ahí, aunque
   ya se haya mostrado en un mensaje anterior o el usuario la haya visto:
   el usuario no debe tener que buscarla ni pedirla aparte. Si hay varios
   mensajes pendientes de autorizar, se imprimen todos, cada uno con su
   destino (tarea, tipo nota/comentario, destinatario). Referir el texto con
   frases como "el texto ya lo tienes" o "la nota que te propuse" cuenta
   como NO haber pedido autorización.
8. **"Notificar al cliente por correo" = mensaje en el chatter de la tarea.**
   En Jarsa casi nunca se mandan correos directos (Gmail). Cuando el usuario
   pida "notificar", "avisar por correo" o "confirmar al cliente" desde una
   tarea, se redacta un comentario para el chatter y Odoo lo envía por correo
   al cliente. Solo se usa Gmail cuando el usuario lo pida explícitamente
   ("mándalo por correo directo / por Gmail"). Envío, tras la autorización de
   la regla 7: `call_method(model='project.task', method='message_post',
   ids=[<task_id>], kwargs={'body': <html>, 'body_is_html': True,
   'message_type': 'comment', 'subtype_xmlid': 'mail.mt_comment',
   'partner_ids': [<partner_id del cliente>]})`.
