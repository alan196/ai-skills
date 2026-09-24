---
name: odoo-functional-docs
description: Documentación funcional de un módulo Odoo para el cliente, paso a paso y con capturas de pantalla (Playwright), entregada como artículo de Knowledge dentro de un módulo knowledge_<cliente>. Activar cuando el usuario pida "documentación funcional", "manual de usuario", "manual con capturas", "documentar el módulo para el cliente" o al cerrar un desarrollo de cliente que tenga etiqueta de documentación pendiente.
---

# Documentación funcional con capturas → Knowledge

Entregable: un artículo de Knowledge por módulo, en español, paso a paso,
con capturas reales de la interfaz, dentro del módulo `knowledge_<cliente>`
del repo del cliente (lo crea la primera vez; después solo se agregan
artículos). NUNCA generar README.md con esta finalidad ni escribir el
artículo a mano en producción: el manual vive en código y se actualiza con
el módulo.

## 1. Entender el módulo
Leer manifest, models, views, wizards, data, security y tests del módulo.
Identificar: configuración inicial, captura diaria, proceso de cierre,
aprobaciones, lo que ve cada rol, y 5-8 preguntas frecuentes reales. No
inventar comportamiento: si no está en el código, no va en el manual.

## 2. Base local con datos demo en español
1. Base de pruebas local (`test190<cliente>`) con el módulo instalado.
2. Activar `es_MX`, poner el admin en español y renombrar la compañía al
   nombre del cliente (las capturas deben verse como su Odoo).
3. Script en `odoo-bin shell` que cree datos con nombres realistas: usuarios
   con los roles del cliente (login = contraseña), registros que cubran cada
   caso del manual (éxito, rechazo, sin derecho, apoyo, etc.) y que deje los
   documentos en los estados que muestran cada botón. Idempotente (buscar
   antes de crear).
4. Servidor local: `odoo-bin -c <conf> -d <bd> --http-port=8090` en segundo
   plano (nohup); reiniciarlo tras instalar módulos.

## 3. Capturas con Playwright
Runtime: `~/.local/pipx/venvs/playwright/bin/python` (chromium instalado con
`python -m playwright install chromium`). Plantilla: `shots_template.py` en
esta carpeta. Reglas que ya costaron tiempo:
- Login: `page.click("form.oe_login_form button[type=submit]")` (hay otro
  submit en la página) y esperar `.o_navbar`. NUNCA `wait_for_load_state
  ("networkidle")`: el bus de Odoo nunca queda idle.
- **Un `browser.new_context()` por usuario**; cerrar el contexto al cambiar
  de rol, si no la sesión anterior se reutiliza.
- URLs: `/odoo/action-<modulo>.<xmlid_accion>` para listas y
  `/odoo/action-<modulo>.<xmlid_accion>/<id>` para formularios; `/new` abre
  el formulario vacío. Los filtros por defecto de la acción pueden ocultar
  el registro (ej. "Vigentes"): crear uno que sí pase el filtro.
- Pestañas: `page.get_by_role("tab", name="Documentos").click()`; esperar
  `.o_form_view` / `.o_list_view` y dormir 2 s antes de la captura.
- Viewport 1440×900, `locale="es-MX"`, nombres `NN_descripcion.png`.
- Envolver cada captura en try/except que guarde `<nombre>_error.png` y
  siga: revisar las fallidas con Read (imagen) antes de arreglar.
- Revisar 2-3 capturas con Read: campo visible, pestaña correcta, botón del
  rol, sin cadenas sin traducir importantes (anotarlas como pendiente de
  i18n del módulo, no arreglarlas aquí).

## 4. Módulo knowledge_<cliente>
Estructura mínima (ver `knowledge_bylack` en 19.0/bylack como referencia):
```
knowledge_<cliente>/
  __manifest__.py        depends: ["knowledge"]; data: raíz + un xml por manual
  data/knowledge_article_data.xml            raíz, <odoo noupdate="1">
  data/knowledge_article_<modulo>_data.xml   manual, actualizable
  static/src/img/<modulo>/NN_*.png           capturas (≈100 KB c/u)
  readme/DESCRIPTION.md USAGE.md CONTRIBUTORS.md
```
- Raíz "Manuales <CLIENTE>": `internal_permission=read`,
  `is_article_visible_by_everyone=True` (si no, no aparece en la barra
  lateral y pide "Unirse"), `article_member_ids` con el admin en `write`
  (Knowledge exige un editor). Va en `noupdate="1"` porque al actualizar no
  se puede reconstruir la lista de miembros (falla el check "needs a writer").
- Manual: `parent_id` a la raíz (hereda permisos), `icon`, `sequence`,
  `body type="html"`. Imágenes con `<img class="img-fluid"
  src="/knowledge_<cliente>/static/src/img/<modulo>/NN.png"/>`: son
  estáticas públicas, sin adjuntos. Sin `noupdate`, para que `-u` refresque.
- Estructura del cuerpo: encabezado (módulo, versión, mes), "Cómo funciona"
  en 5-6 viñetas, Configuración inicial, Durante el mes, Cierre/proceso
  principal, Aprobaciones, casos especiales, Lo que ve cada rol, FAQ. Cada
  paso nombra menús y etiquetas exactamente como en pantalla (Ventas ›
  Comisiones › Metas de comisiones) y va seguido de su captura.
- USAGE.md de knowledge_<cliente> lista los manuales que trae.

## 5. Traducciones antes de capturar
Activar el idioma ANTES de crear los datos demo (si no, actividades y
mensajes del chatter quedan en inglés) y revisar que los datos del módulo
(`data/*.xml`) tengan `translate=True` en sus `name` y su traducción en
`es.po`; si algo sale en inglés en una captura, es un pendiente de i18n del
módulo que se corrige en el mismo MR (un commit por módulo, siempre `es.po`).

## 6. Validar
`-i` limpio, `-u` dos veces y desinstalar/reinstalar: sin duplicados ni
errores. Capturar el artículo con Playwright como un usuario normal (no
admin) y comprobar que aparece en "Espacio de trabajo" y renderiza imágenes.
pre-commit-vauxoo, commit, MR con `task#<id>`. Nota en la tarea (con
autorización, ver jarsa-task-sync) enlazando el MR y el nombre del artículo.

## Al agregar un manual a un cliente que ya tiene knowledge_<cliente>
Solo: nuevo `data/knowledge_article_<modulo>_data.xml` + carpeta de imágenes
+ línea en el manifest y en USAGE.md + subir versión `y` del módulo.
