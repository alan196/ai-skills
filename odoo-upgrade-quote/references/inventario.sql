-- Levantamiento para cotizar una migración de Odoo (15.0–19.0).
-- Uso: psql -d <bd> -f inventario.sql > inventario_<cliente>.txt
-- Sin ON_ERROR_STOP: las consultas de módulos no instalados fallan y se ignoran.
\pset pager off
\echo '== Tamaño, compañías, usuarios, volumen'
SELECT pg_size_pretty(pg_database_size(current_database())) AS bd;
SELECT latest_version FROM ir_module_module WHERE name = 'base';
SELECT count(*) AS companias FROM res_company;
SELECT count(*) AS usuarios_internos FROM res_users WHERE active AND NOT share;
SELECT count(*) AS apuntes FROM account_move_line;
SELECT min(date) AS primer_asiento FROM account_move;

\echo '== Módulos instalados con autor/origen (cruzar con addons nativos en local)'
SELECT name, author, latest_version FROM ir_module_module
 WHERE state = 'installed' ORDER BY author, name;

\echo '== Personalización sin módulo'
SELECT count(*) AS campos_manuales FROM ir_model_fields WHERE state = 'manual';
SELECT count(*) AS modelos_manuales FROM ir_model WHERE state = 'manual';
SELECT count(*) AS vistas_sin_modulo FROM ir_ui_view v
 WHERE NOT EXISTS (SELECT 1 FROM ir_model_data d WHERE d.model = 'ir.ui.view' AND d.res_id = v.id
                     AND d.module NOT IN ('__export__', 'studio_customization'));
SELECT count(*) AS vistas_studio FROM ir_model_data WHERE module = 'studio_customization' AND model = 'ir.ui.view';

\echo '== Acciones de servidor con código que no vienen de un módulo'
SELECT a.id, a.name::text, m.model, length(a.code) AS chars
  FROM ir_act_server a JOIN ir_model m ON m.id = a.model_id
 WHERE a.state = 'code'
   AND NOT EXISTS (SELECT 1 FROM ir_model_data d WHERE d.model = 'ir.actions.server' AND d.res_id = a.id
                     AND d.module NOT IN ('__export__', 'studio_customization'))
 ORDER BY a.id;

\echo '== Crons activos'
SELECT c.id, a.name::text, c.interval_number, c.interval_type
  FROM ir_cron c JOIN ir_act_server a ON a.id = c.ir_actions_server_id WHERE c.active;

\echo '== Integraciones y parámetros'
SELECT key FROM ir_config_parameter ORDER BY key;
SELECT name, smtp_host FROM ir_mail_server;
SELECT name, l10n_mx_edi_pac, l10n_mx_edi_pac_test_env FROM res_company;  -- solo MX

\echo '== Opcionales (fallan si el módulo no está)'
SELECT count(*) AS reglas_automatizadas FROM base_automation WHERE active;
SELECT count(*) AS vistas_sql FROM bi_sql_view;
SELECT count(*) AS unidades_operativas FROM operating_unit;
