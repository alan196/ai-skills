# Términos, pagos y cotización formal en Odoo

## Esquema de pagos (aceptado por MTNMX, v8)

| Pago | % | Fecha / condición |
|---|---|---|
| Anticipo | 20 | A la firma, con pagaré |
| Mensualidades ×4 | 15 c/u | Día 5 de cada mes, contra reporte mensual de avance |
| Retención 1 | 10 | 30 días naturales después del arranque |
| Retención 2 | 10 | 60 días después del arranque, al cerrar la garantía |

La pena por retraso **no va en la propuesta base**. Solo se agrega si el
cliente la pide; en ese caso se aplica sobre las retenciones (ver sección 6).

- El número de mensualidades se ajusta a la duración del proyecto; el total
  debe dar 100 %.
- Redondeo: el último pago absorbe los centavos para que la suma sea igual al
  subtotal. En Odoo, el IVA calculado por línea puede diferir 1 centavo del
  Excel; es aceptable.
- Si el cliente ofrece pagos por hitos, contraofrecer mensualidades: Jarsa
  necesita flujo mensual.

## Cláusulas (sección por sección, como en la hoja Propuesta)

1. **Inversión:** precio cerrado. Las horas son base de cálculo, no un tope.
   En MXN, más IVA.
2. **Pago:**
   - Vencimiento a 15 días naturales de la factura.
   - Suspensión de los trabajos si hay una factura vencida más de 30 días.
   - Las mensualidades no se recorren si el cliente se atrasa.
3. **Alcance:**
   - BD completa con upgrade.odoo.com: 3 ensayos y la migración final.
   - N módulos no nativos (anexo Módulos).
   - Tests al 80 % (si aplica).
   - La personalización sin módulo según el inventario firmado en la fase 1.
   - Acciones de servidor: solo la lista del cliente (anexo).
   - Integraciones, listadas por nombre.
   - Capacitación, 2 semanas de soporte reforzado y garantía.
4. **Equipo:**
   - Jarsa: nombres y porcentajes de dedicación. Se menciona el uso de IA,
     con revisión humana de todo cambio.
   - Cliente: 1 líder (≈4 h a la semana) y usuarios clave por área, con sus
     horas estimadas para UAT.
5. **Comunicación:**
   - Canal oficial: tareas del proyecto en el portal de Jarsa.
   - Junta semanal con minuta en 24 h.
   - WhatsApp solo para urgencias; no sirve para cambios ni aceptaciones.
6. **Tiempo y calidad:**
   - Fecha de arranque comprometida (fin de semana), con margen hasta el
     31/03.
   - **Pena (opcional, solo si el cliente la pide):** 2.5 % del contrato por
     semana tras 4 semanas de gracia. Se aplica primero a la retención 1 y
     después a la 2. Tope: 20 % (8.ª semana).
   - El plazo se recorre sin pena si:
     - el cliente tarda más de 3 días hábiles en responder;
     - hay un cambio de alcance;
     - la causa es de Odoo S.A.
   - **Liberación del upgrade (solo si el destino es la versión nueva):** si
     al 15/01 Odoo no libera el upgrade, la fecha se recalcula a 4 semanas
     después de la liberación, sin pena. Si por esa causa el arranque pasa del
     31/03, el cargo de soporte extendido es del cliente.
   - La pena, si se pactó, es la única responsabilidad económica de Jarsa por
     tiempo. El cargo de Odoo nunca se traslada a Jarsa. **No ofrecer cubrir
     el 25 %**: pedirían pena + cargo.
   - Garantía de 60 días para defectos de migración:
     - bloqueantes, el mismo día hábil;
     - los demás, en 5 días hábiles.
   - Aceptación con guiones firmados. Aceptación tácita a los 5 días hábiles.
     Cierre a 30 días del arranque.
7. **Congelamiento:**
   - Fecha y commit de referencia.
   - Desarrollos en curso incluidos por nombre (con sus horas).
   - Los fixes menores posteriores se registran en la tarea para llevarlos a
     la versión destino.
   - Lo mayor se cotiza aparte y puede mover la fecha.
   - Si el cliente commitea al repo, el congelamiento es obligatorio.
8. **No incluye:**
   - desarrollos nuevos, rediseño de procesos, manuales;
   - licencias de Odoo y Odoo.sh;
   - renovación de la anualidad L.M.E.;
   - acciones de servidor fuera de la lista.

Contra el contrato 15→17 de MTNMX, estas cláusulas evitan:
- el pago final "a entera satisfacción";
- la retención del 40 %;
- la corrección de errores sin límite de garantía.

## sale.order formal por MCP (Odoo de Jarsa)

Nombres de campo en esta versión: `product_uom_id`, `tax_ids`, `unspsc_code_id`.
sale.order no tiene `analytic_account_id`; se usa `analytic_distribution` en
las líneas.

1. Crear la sale.order con:
   - `partner_id`: el contacto principal del cliente;
   - `user_id` 2 (Alan), `team_id` 1, `company_id` 1, `pricelist_id` 1;
   - `payment_term_id` 18 ("15 días");
   - `validity_date` a 30 días;
   - `require_signature` true y `require_payment` false.
2. Líneas:
   - una sección con el título;
   - una línea por pago, con producto 365 `[IMP] Implementación Odoo`, qty 1,
     `tax_ids` [2] (IVA 16 %) y `analytic_distribution` `{"<analítica del proyecto>": 100}`;
   - descripción: "<Pago> (<n> %) — Facturación: <fecha o condición> —
     Vencimiento: 15 días naturales después de la factura".
3. `note` (HTML con etiquetas reales, no entidades): los T&C de arriba, en
   secciones.
4. Adjuntar el Excel a la SO: `ir.attachment.copy` con
   `default: {res_model: 'sale.order', res_id}` si ya existe en la tarea;
   comparar el checksum.
5. **Mostrar la SO a Alan y esperar su revisión.**
6. Enviar el correo:
   1. `action_quotation_send` da el contexto (template 17).
   2. Crear `mail.compose.message` con `template_id` 17 y ese contexto; el
      template genera el PDF actualizado.
   3. Cambiar `partner_ids`: solo a quien Alan indique. El email del partner
      principal puede traer varias direcciones.
   4. Poner el asunto, los adjuntos (PDF + Excel) y el cuerpo.
   5. **Mostrar el texto íntegro y esperar autorización.**
   6. Llamar a `action_send_mail`. La SO pasa a "sent".
