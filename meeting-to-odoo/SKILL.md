---
name: meeting-to-odoo
description: Process meeting/video-call transcripts into Odoo. Trigger whenever the user
  shares a meeting transcript, minutes, or recording notes (pasted text or a local
  .txt/.md/.docx/.pdf file), or asks to generate a minuta, log meeting hours, or create
  tasks from meeting commitments for a client project.
---

# Meeting to Odoo

Flujo para convertir la transcripción de una videollamada o reunión presencial
en: registro de horas, minuta y tareas documentadas en Odoo (requiere el MCP
server de Odoo; si sus herramientas no están disponibles, avisa al usuario y
detente). La conversación con el usuario es en español mexicano; nombres
técnicos de campos, modelos y tablas SIEMPRE en inglés.

## Paso 0 — Ingesta del transcript

1. Aceptar la transcripción como texto pegado en el chat o como archivo local
   (`.txt`/`.md` leer directo; `.docx`/`.pdf` con las herramientas de lectura
   disponibles).
2. Extraer del transcript: fecha de la reunión, lista de asistentes,
   timestamps (para calcular duración) y temas tratados.

## Paso 1 — Contexto de proyecto (obligatorio antes de cualquier escritura)

1. Verificar si la conversación ya tiene identificado un proyecto de Odoo. Si
   no, inferir el cliente del transcript y resolver con
   `find_project_for_client(partner_name=<cliente>)` o `list_projects`.
2. Si hay varias candidatas o ninguna coincidencia clara: **detenerse y
   preguntar** al usuario qué proyecto usar. Nunca adivinar el proyecto ni
   escribir nada en Odoo sin proyecto confirmado.

## Paso 2 — Clasificación de asistentes (bloqueante)

1. Clasificar cada asistente como **Jarsa** o **cliente**:
   - usuarios internos con `list_users`;
   - si el transcript incluye correos, dominio `@jarsa.com` = Jarsa.
2. Por cada asistente que no se pueda clasificar con certeza: **preguntar
   directamente al usuario** y NO continuar con los siguientes pasos hasta
   tener la clasificación completa.

## Paso 3 — Tarea de la reunión, horas y anti-duplicados

1. Buscar en el proyecto una tarea existente que corresponda al **tema de la
   reunión** (`list_tasks` / `search_read` sobre `project.task`, comparando
   título y contenido). Si hay coincidencia clara → usar esa tarea; si hay
   varias candidatas o ninguna → mostrar opciones y preguntar antes de crear
   una nueva con `create_task`.
2. **Anti-duplicado de horas:** antes de registrar, leer las líneas de
   timesheet de la tarea (`read_records` sobre `account.analytic.line`
   filtrando `task_id`, `date` y usuario actual). Si ya existe un registro de
   esa reunión (misma fecha y descripción `Reunión YYYY-MM-DD - <tema>`), NO
   volver a registrar; avisar al usuario.
3. Duración: calcularla con los timestamps del transcript (o el evento de
   Google Calendar si está disponible); si no hay datos, preguntar.
   **Siempre confirmar las horas con el usuario** antes de llamar
   `log_timesheet(task_id, hours, description='Reunión YYYY-MM-DD - <tema>')`.
   Registrar horas solo a nombre del usuario actual, nunca de terceros.

## Paso 4 — Minuta

1. Generar la minuta en español con este formato exacto:

   ```
   # Minuta — <YYYY-MM-DD> — <tema>

   ## Asistentes
   (agrupados: Jarsa / <empresa del cliente>)

   ## Actividades realizadas

   ## Acuerdos y decisiones

   ## Compromisos
   (agrupados por empresa → participante, con fecha compromiso si se mencionó)

   ## Riesgos y bloqueos
   (con responsable de resolución)

   ## Próxima reunión
   (solo si se acordó)
   ```

2. Escribirla en dos lugares:
   - `update_task` **anexando** la minuta al final de la descripción
     existente, separada por un encabezado con la fecha. NUNCA borrar ni
     reemplazar el contenido previo de la descripción.
   - `post_task_message` como nota interna en el chatter (deja historial con
     fecha), con `notify_followers=false`.

## Paso 5 — Compromisos → tareas del proyecto

Por cada compromiso detectado en la minuta:

1. Buscar en las tareas del proyecto una tarea existente que corresponda al
   compromiso (similitud de título/tema).
2. **Si existe:** enriquecer su descripción con el detalle de lo que debe
   realizarse (anexar, no reemplazar) y avisar al usuario qué tarea se
   actualizó.
3. **Si no existe:** agregarla a una tabla propuesta con: título, responsable
   sugerido, descripción detallada, tiempo estimado en horas y deadline (si se
   mencionó fecha). Crear con `create_task` SOLO las que el usuario confirme.
4. **Si el compromiso es planeación de un desarrollo:** activar la skill
   `odoo-development` para aplicar sus estándares y producir documentación
   técnica detallada en la descripción de la tarea, que incluya:
   - modelos y tablas afectados (nombres técnicos siempre en inglés,
     `snake_case`, p.ej. `sale.order`, `x_delivery_date`);
   - campos a crear: nombre técnico, tipo de campo y **justificación de la
     creación de cada campo**;
   - vistas, seguridad (`ir.model.access.csv`) y dependencias afectadas
     cuando aplique;
   - tiempo estimado de desarrollo (setear `allocated_hours` en la tarea).
5. Fechas comprometidas → aplicar con `set_deadline`; responsable → sugerir
   con `suggest_assignee` y asignar con `assign_task`. Ambos solo con
   confirmación del usuario.

## Paso 6 — Extras

1. Si en la reunión se acordó una próxima reunión con fecha/hora: ofrecer
   crear el evento con el MCP de Google Calendar. Solo crearlo si el usuario
   acepta; si las herramientas de Calendar no están disponibles, avisar y
   continuar sin bloquear.

## Reglas de seguridad

1. Nunca escribir en Odoo sin haber resuelto proyecto (Paso 1) y
   clasificación de asistentes (Paso 2).
2. `notify_followers=false` por defecto en todos los mensajes; `dry_run=true`
   primero en movimientos de etapa y cambios masivos, aplicar solo tras
   confirmación del usuario.
3. Al terminar, dar un resumen al usuario: horas registradas, tareas creadas
   y actualizadas, con sus IDs y links.
