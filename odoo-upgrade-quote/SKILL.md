---
name: odoo-upgrade-quote
description: Analiza la base de datos y el código de un cliente de Jarsa (por SSH a Odoo.sh o con respaldo SQL + código local) y genera la propuesta de migración de Odoo a precio fijo (Excel + sale.order en el Odoo de Jarsa + correo). Usar cuando el usuario pida cotizar, estimar o proponer un upgrade/migración de versión de Odoo para un cliente, o mencione la fecha límite del 1 de abril para versiones anteriores a 18.0.
---

# Propuesta de migración de Odoo (precio fijo)

Proceso sacado del caso MTNMX 17.0→20.0 (tarea 32509, SO2104, sep-2026): fueron
8 versiones de propuesta. Este skill existe para que el siguiente cliente salga
en 1 o 2. **Una sesión por cliente.** Las reglas de `jarsa-task-sync` aplican
completas (tarea, horas, chatter). La regla 7 de esa skill es inviolable: nada se
envía al cliente sin autorización con el texto íntegro a la vista.

Referencias en este directorio:
- `references/inventario.sql`: consultas del levantamiento. Sirven en Odoo 15 a 19.
- `references/estimacion.md`: escala de horas, tarifas, plan por fases y cálculo del precio.
- `references/terminos.md`: esquema de pagos, cláusulas y cómo crear y enviar la SO por MCP.

## Contexto de negocio (no volver a preguntarlo)

- Política de Odoo: una versión deprecada entra a soporte extendido. Antes del
  **1 de abril** el cliente debe estar en una versión soportada (18, 19 o 20).
  Si no lo logra, Odoo cobra el soporte extendido anual completo (25 % de la
  anualidad, sin prorrateo). Ese cargo nunca se traslada a Jarsa.
- **Destino por defecto: 20.0.** El upgrade a 20.0 suele liberarse en
  upgrade.odoo.com entre diciembre y enero, así que el contrato lleva la
  **cláusula de liberación** (ver `terminos.md`). La propuesta explica ese
  riesgo y ofrece 19.0 como alternativa para el cliente que no quiera correrlo.
  Siempre se propone 20.0.
- **Cliente en DeployV:** ya paga una cuota mensual de migración. No se cotiza
  la migración; solo se planea.
- Los timesheets de proyectos a precio fijo anteriores NO sirven como costo
  real (en el 15→17 de MTNMX casi no se registraron). Se estima por alcance.
- Lo que falló en el 15→17 fue la dedicación de Alan, no la migración de Odoo.
  Alan es el cuello de botella: el calendario se valida contra su capacidad
  sumando todos los clientes en migración, no por cliente aislado.

## Flujo

### 0. Arranque
1. Identificar al cliente, el proyecto y la tarea en el Odoo de Jarsa (MCP
   `claude_ai_Odoo`). Si no hay tarea, crearla según `jarsa-task-sync`.
2. Buscar antecedentes del cliente en el MCP: SO de migraciones anteriores
   (tarifas pactadas, cláusulas, qué se cobró de verdad), la tarifa por hora
   vigente en sus SO de horas y las anualidades L.M.E. (producto `[LMEM]`). Los
   módulos l10n_mx cubiertos por la anualidad se migran **sin cargo**: sus
   horas van en el plan pero no suman al precio.
3. Anualidad de licencias Odoo del cliente: con ella se calcula el 25 % del
   soporte extendido. Es el argumento para descartar un plan B.

### 1. Acceso a los datos
- **Odoo.sh:** `ssh <build>@<proyecto>.odoo.com` (el ProxyJump al bastión
  192.99.15.215 ya está en `~/.ssh/config`). Si da timeout en el puerto 22, NO
  reintentar: avisar a Alan que permita la IP. Usar **staging**, nunca
  producción, salvo para lecturas que el usuario autorice. Ahí:
  `psql -f inventario.sql` y `du -sh ~/data/filestore/*`.
- **Respaldo (clientes fuera de Odoo.sh):** preguntar a Alan dónde está el
  respaldo y si se restaura en local; no suponer la ubicación. Si se restaura:
  - en `~/proyectos/<versión>/`, con `createdb` y `psql`/`pg_restore`;
  - no hace falta el filestore: su tamaño se pregunta o se toma del zip;
  - nunca levantar Odoo sobre el respaldo sin `--neutralize` o con los crons
    encendidos.

  La migración en sí también se hace con respaldo local, y eso se refleja en
  el plan.
- **Código:** repo del cliente en git.jarsa.com (Jarsa/<cliente>) y su
  `oca_dependencies.txt`. Contar líneas `.py`/`.xml` por módulo custom y los
  tests que tiene (`tests/`).

### 2. Levantamiento
Correr `references/inventario.sql` y armar la tabla de módulos no nativos,
cada uno con:
- origen: custom del cliente, OCA, Vauxoo/L.M.E., AMOdoo, Jarsa u otro;
- líneas de código y si tiene tests;
- versión más reciente disponible de módulos de terceros: para OCA, revisar si
  existe la rama destino en GitHub (`gh api repos/OCA/<repo>/branches`) y si el
  módulo está en ella o en un PR abierto;
- si Odoo nativo del destino ya lo cubre (proponer migrar datos a lo nativo);
- clase XS–XL y bloque (A terceros, B críticos contables, C operativos).

También la personalización sin módulo: campos y modelos manuales, vistas sin
xmlid de módulo, acciones de servidor con código, reglas automatizadas, vistas
SQL (bi_sql_editor), Studio. Y las integraciones: PAC, SAT, bancos, correo,
calendarios, APIs.

**Acciones de servidor:** no cotizar todas. Pedir al cliente la lista de las
que usa. En MTNMX quedaron 38 de 191, y la lista se volvió anexo del contrato.

### 3. Estimación y precio
Seguir `references/estimacion.md`. Se entrega el **modelo interno** (costo,
margen, capacidad por persona) para Alan y la **propuesta** para el cliente
(sin costos internos ni tarifas de sueldo).

### 4. Entregables (solo Excel y SO; sin deck)
1. Excel de propuesta en `~/Documents/Proyectos/<CLIENTE>/<CLIENTE>_Propuesta_upgrade_<origen>_a_<destino>.xlsx`
   con 3 hojas: Propuesta, Plan de trabajo, Módulos. Tomar como plantilla la
   estructura del de MTNMX (`~/Documents/Proyectos/MTNMX/MTNMX_Propuesta_upgrade_17_a_20.xlsx`)
   (copia en `references/plantilla_propuesta_mtnmx_v8.xlsx`: copiarla y editar en sitio) y usar fórmulas (Subtotal, IVA, pagos = % × subtotal).
2. Cuando el cliente acepte: sale.order formal, una línea por pago, y el
   correo desde la SO (ver `terminos.md`).

### 5. Iteración con el cliente
- Alan edita el Excel a mano. **Antes de cada cambio, comparar contra la última
  versión generada y editar en sitio con openpyxl. Nunca regenerarlo desde un
  script.** Respaldar cada versión en el scratchpad (`backup_vN.xlsx`).
- openpyxl `insert_rows` NO desplaza fórmulas: reescribir las de abajo.
- Ajustes típicos de negociación, con el precio recalculado cada vez:
  - quitar o devolver la cobertura de tests;
  - recortar las acciones de servidor a la lista del cliente;
  - cambiar la garantía de 60 a 30 días;
  - pasar los pagos de hitos a mensualidades (Jarsa necesita flujo mensual).
- Si el cliente ancla en el precio de la migración anterior, comparar precio
  por módulo y número de versiones (MTNMX: $15.7 k/módulo vs $5.9 k).
- Cada versión enviada se registra en la memoria del proyecto con: número,
  precio, attachment id y qué cambió.

### 6. Cierre de sesión
Registrar horas en la tarea. Reportar Hecho / Pendiente. Guardar en memoria el
estado del cliente: versión enviada, precio y siguiente paso.

## Errores conocidos
- En Odoo 16+, `name` de acciones, modelos, campos y vistas es jsonb: usar
  `name->>'es_MX'` o `name->>'en_US'`. `inventario.sql` ya lo maneja con `::text`.
- Adjuntar a una tarea de Odoo 17 por Chrome: el input file del chatter solo
  existe tras abrir "Registrar una nota". Luego `message_post` con
  `attachment_ids` por MCP.
