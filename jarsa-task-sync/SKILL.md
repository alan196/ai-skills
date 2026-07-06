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
     request plus the implementation plan (markdown).
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
5. Never notify followers (`notify_followers` stays false) unless the user
   asks. Use `dry_run=true` first for stage moves and bulk changes, and apply
   only after the user confirms.
