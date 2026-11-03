---
name: odoo-development
description: Standards and rules for developing, testing, and running Odoo on this machine.
---

# Odoo Development Rules and Standards

When developing or interacting with Odoo on this computer, always follow these rules:

1. **Project Structure & Virtual Environments:**
   - Projects are strictly organized by version: `~/proyectos/<version-de-odoo>/<repos>` (e.g., `~/proyectos/17.0/odoo`, `~/proyectos/19.0/enterprise`).
   - Every Odoo version requires a different Python virtual environment managed by pyenv. The environment names follow the pattern `odoo<VERSION>` (e.g., `odoo170`, `odoo190`).

2. **Running Odoo in Subprocesses:**
   - **NEVER** use the interactive zsh functions (e.g., `odoo170`, `odoo170shell`, `odoo170translate`, `odoo170-sh`, `pyenv shell`, `odoo190`) defined in `~/.zshrc`. These wrappers only work in interactive shells and will fail when executed as background tasks or subprocesses by AI agents.
   - **NEVER** prefix commands with `PYENV_VERSION=...` — the direct venv binary already resolves the version.
   - **ALWAYS** use the direct binary from the pyenv virtual environment. pyenv exposes two equivalent paths (both work):
     - `~/.pyenv/versions/<PYTHON>/envs/odoo<VERSION>/bin/python3` (full path, e.g. `.../3.10.14/envs/odoo170/...`)
     - `~/.pyenv/versions/odoo<VERSION>/bin/python3` (symlink shortcut)
   - The execution pattern for ANY Odoo version is:
     `~/.pyenv/versions/odoo<VERSION>/bin/python3 ~/proyectos/<VERSION>/odoo/odoo-bin -c ~/proyectos/<VERSION>/odoo-server.conf -d <database_name> [options]`
   - Example for Odoo 19.0:
     `~/.pyenv/versions/odoo190/bin/python3 ~/proyectos/19.0/odoo/odoo-bin -c ~/proyectos/19.0/odoo-server.conf -d test190`

3. **Pre-commit Execution:**
   - Before committing any Odoo module, check if the repository root has a `variables.sh` file.
   - **IF `variables.sh` EXISTS:** Run `pre-commit-vauxoo` exactly as is, without any subcommands and **without** a dot at the end. DO NOT run standard `pre-commit run`. This can be run from the repo root (`cd <repo> && pre-commit-vauxoo`) or a specific module (`cd <repo>/<module> && pre-commit-vauxoo`).
   - **IF `variables.sh` DOES NOT EXIST:** When creating or modifying an Odoo module, you MUST execute `pre-commit run --all-files`.
   - Never use the sub-command `run`, the `-p` flag, or a dot `.` with `pre-commit-vauxoo`.
   - **REGLA INQUEBRANTABLE — ningún push ni MR/PR sale con pre-commit en rojo.** El pre-commit que cuenta es el que corre DESPUÉS del último cambio, sobre lo que realmente se va a pushear; uno corrido antes de la última edición no vale. Compuerta obligatoria antes de cada `git push` y antes de crear/actualizar un MR/PR:
     1. Correr pre-commit desde la RAÍZ del repo (el CI corre ahí; desde una subcarpeta puede dar otro resultado).
     2. NO confiar en el exit code: en local `pre-commit-vauxoo` termina en 0 aunque el autofix haya reformateado, y en el CI ese mismo caso es `exit 1`. Leer el resumen: `Autofix checks`, `Mandatory checks` y `Optional checks` deben decir `Passed`. `Reformatted` cuenta como FALLA.
     3. Si reformateó archivos, agregarlos al commit (amend/fixup del commit que los tocó) y VOLVER a correr hasta que todo salga `Passed` y `git status` quede limpio. Solo entonces push.
     4. Si el CI reporta algo que en local no sale, comparar versiones: el log del CI imprime `pre-commit-vauxoo==X.Y.Z`; igualarla con `pipx upgrade pre-commit-vauxoo` (o `pipx install --force pre-commit-vauxoo==X.Y.Z`) y repetir.
     5. Nunca escribir "pre-commit green" en la descripción de un MR/PR ni en un reporte sin haber hecho los pasos 1-3 sobre el HEAD que se pusheó.
     6. Después del push, revisar el job `precommit` del pipeline del MR; si falla, corregirlo antes de dar el trabajo por terminado.
   - **Inline linter silencing** (`# pylint: disable=...`, `# noqa`, etc.): only allowed when an Odoo-standard pattern forces it (e.g. the `SELF_READABLE_FIELDS` / `SELF_WRITEABLE_FIELDS` property overrides on `res.users` trip `invalid-name`). In every other case fix the code instead of silencing the check. Never disable a check repo-wide (`PYLINT_DISABLE_CHECKS` in `variables.sh`, editing `.pylintrc`) to avoid an inline comment: the scoped inline disable is preferable to losing the check everywhere. In pre-commit-vauxoo repos the generated `.pylintrc` is overwritten on every run — never edit it.

4. **Code and Module Generation Standards:**
   - Always ensure that your code complies with OCA development standards.
   - Standard module structure: `__manifest__.py`, `models/`, `views/`, `security/`, `i18n/`, `static/`.
   - Unit tests are mandatory from the beginning.
   - **Translations:** Always use `i18n/es.po` for Spanish translations regardless of the Odoo version. Do not use `es_MX.po`, as Odoo supports the general `es.po` globally now.
   - Manifest: Use `license: LGPL-3` if the module is OCA, or the client's license if otherwise.
   - **README — only when CREATING a new module:** In OCA repos or `amxodoo-enterprise`, ALWAYS use the `readme/` folder with fragments (`DESCRIPTION.md`, `USAGE.md`, `CONFIGURE.md`, `CONTRIBUTORS.md`, `ROADMAP.md`, …). DO NOT write `README.rst` by hand — it is generated by the `oca-gen-addon-readme` hook from those fragments.
   - **Crucial Odoo 17+ Rules:** DO NOT use `page="True"` in QWeb templates (causes errors). DO NOT include `\n` in the `subject` field of `mail.template`.
   - Never include legends or comments indicating the code was generated by AI.

5. **Testing and Debugging:**
   - Always request the full traceback before proposing a solution when debugging.
   - Consider the active Odoo version before suggesting APIs.
   - When writing tests, inherit from `odoo.tests.common.TransactionCase` or `SavepointCase` according to the version.
   - Minimum expected coverage is 80%. Name test methods properly: `test_<functionality>`.

6. **Mandatory Unit-Test Validation Flow:**
   Every development/fix of an Odoo module is validated by running its unit tests before considering it done.
   1. If NO test database exists, create it with demo data and install the module's DEPENDENCIES WITHOUT tests (this creates the DB if missing). Leave the module under test NOT installed yet:
      `... -d <test_db> -i <dependencies> --stop-after-init`
   2. Run the tests by installing the module with `-i` (NOT `-u`: if the module is already installed, `-u` does not re-run tests on reload; with `-i` it installs and runs at_install + post_install):
      `... -d <test_db> -i <module> --test-enable --test-tags /<module> --stop-after-init`
   3. When development is finished, ASK whether to drop the test DB and its filestore (`dropdb <test_db>` and `rm -rf <data_dir>/filestore/<test_db>`) to avoid accumulating databases.
   - NEVER install/test against production databases (e.g. `mtnmx170`).

7. **Security and Group Permissions:**
   - **REGLA INQUEBRANTABLE — todo modelo nuevo lleva ACL, incluidos los wizards (`TransientModel`).** Desde Odoo 17 los modelos transitorios NO tienen acceso implícito: sin línea en `security/ir.model.access.csv` el botón que abre el wizard truena con "No puede acceder a los registros ... Ningún grupo permite esta operación". Los tests NO lo detectan porque `TransactionCase` corre como superusuario. Por eso, en cada módulo con modelos nuevos:
     1. Crear `security/ir.model.access.csv` con una línea por modelo (wizards incluidos) y ponerlo PRIMERO en la lista `data` del manifest (salvo la excepción de grupos creados después, abajo).
     2. Elegir el grupo con criterio: `base.group_user` solo si cualquier usuario interno puede usarlo; si la acción es administrativa (crear repos, tocar tokens, configuración) usar el grupo de gerente de la app (`project.group_project_manager`, `account.group_account_manager`, ...) y decirlo en el reporte.
     3. Agregar SIEMPRE un test que ejerza el flujo con un usuario real del grupo (`with_user(user)` con un `res.users` creado en el test con solo ese grupo), no como superusuario: es la única forma de que el test falle si falta el ACL.
     4. Antes de dar el módulo por terminado, revisar a mano que cada `_name` nuevo del módulo tenga su línea en el CSV (`grep -rn "_name = " <modulo>/ | wc -l` vs. líneas del CSV).
   - Si te pido restringir un permiso a una vista o botón, siempre busca la opción de asignar permiso a un grupo de seguridad, pregunta si es necesario crear un grupo de seguridad específico o agregarlo a un grupo existente, en vez de restringir a uno, evita usar `!group.security_group` a menos que sea estrictamente necesario por el requerimiento.
   - **ACLs siempre en `ir.model.access.csv`, nunca como records XML** (`<record model="ir.model.access">`), para tener todos los accesos del módulo centralizados en un solo archivo.
   - Si una línea del CSV referencia un grupo que se crea en un archivo de datos posterior (ej. el grupo delegado `<rol>_res_groups` de `base_user_role`), la solución preferida es mover `security/ir.model.access.csv` DESPUÉS de ese archivo en la lista `data` del manifest, en vez de pasar los ACLs a XML.
   - Solo si por alguna razón fuera obligatorio definir un ACL como record XML, justifica el motivo y PREGUNTA antes de hacerlo.

8. **OCA Guidelines — REGLA INQUEBRANTABLE:**
   - **Todo módulo, nuevo o modificado, cumple las OCA Guidelines**
     (https://github.com/OCA/odoo-community.org/blob/master/website/Contribution/CONTRIBUTING.rst).
     Aplica también en repos privados de cliente: pre-commit-vauxoo no valida la
     mayoría de estos puntos, así que se revisan a mano antes de commitear.
   - **Nombre del módulo:** singular; prefijo `base_` si sirve de base para otros;
     `l10n_CC_` para localizaciones; al extender un módulo de Odoo, el nombre de
     ese módulo va primero (`mail_forward`, `crm_partner_firstname`).
   - **Estructura de directorios:** `controllers/ data/ demo/ i18n/ migrations/
     models/ readme/ reports/ security/ static/ templates/ tests/ views/ wizards/`.
     En plural `reports/`, nunca `report/`. `README.rst` se GENERA desde `readme/`:
     jamás se escribe a mano, y no debe existir un `README.md` al lado.
   - **Nombres de archivo:** un archivo por modelo, `models/<modelo>.py`,
     `views/<modelo>_views.xml`, `data/<modelo>_data.xml`,
     `demo/<modelo>_demo.xml`, `security/<modelo>_security.xml`. Solo `[a-z0-9_]`.
   - **xml_id:**
     - vista: `<modelo>_view_<tipo>` (`form`, `list`, `search`, `kanban`, ...)
     - acción: `<modelo>_action`, y `<modelo>_action_<detalle>` si hay varias
     - menú: `<modelo>_menu`
     - grupo: `<modelo>_group_<nombre>`
     - regla: `<modelo>_rule_<grupo>`
     - dato: `<modelo>_<nombre>`; los de demo llevan sufijo `_demo`
     - nunca prefijar con el módulo actual, y al heredar se conserva el nombre
       del xml_id original si el original no sigue la convención
   - **XML:** cuatro espacios; `id` antes de `model`; en los campos, `name`
     primero; `<odoo>` para datos actualizables y `<odoo noupdate="1">` para los
     que no, `<data>` solo para mezclar; nada de `string=` en `<list>`; evitar
     `position="replace"` (si es imprescindible, comentar el motivo y subir la
     `priority` por encima de 100).
   - **Python:** orden de atributos en el modelo — privados, campos, constraints
     SQL, defaults, computes en el mismo orden que los campos, constrains y
     onchanges, CRUD, acciones y al final el resto. Métodos `_compute_<campo>`,
     `_inverse_<campo>`, `_search_<campo>`, `_default_<campo>`,
     `_onchange_<campo>`, `_check_<constraint>`, `action_<accion>`. Constantes en
     MAYÚSCULAS. Nunca `cr.commit()` ni SQL crudo si el ORM puede hacerlo.
   - **Campos:** sufijo `_id` en Many2one y `_ids` en One2many/Many2many; omitir
     `string=` cuando coincide con el nombre técnico; defaults con
     `lambda self: self._default_x()` para que se puedan heredar.
   - **CSS/SCSS:** toda clase se prefija `o_<nombre_tecnico_del_modulo>`.
   - **Manifest:** sin claves vacías, con `license`, `summary` y `category`;
     versión `<serie>.x.y.z` — `x` cambia el modelo de datos, `y` agrega
     funcionalidad, `z` corrige. **Subir la versión en CADA cambio funcional:**
     Odoo.sh y muchos despliegues solo actualizan un módulo cuando cambia su
     versión, así que sin ese bump el código llega al disco y la base se queda
     con el esquema viejo.
   - **Excepción documentada:** no renombrar el xml_id de un `res.groups` ya
     desplegado. Odoo borra el registro viejo al actualizar y los usuarios
     pierden ese grupo. Si el nombre no cumple, se deja y se anota el motivo.

9. **Module Dependencies:**
   - Al definir las dependencias de los módulos, debes poner solo dependencias finales. Por ejemplo, si tienes `helpdesk`, `stock` y `helpdesk_stock`, solo debes poner `helpdesk_stock` y omitir los demás.

10. **Base User Role and Demo Data:**
   - **REGLA INQUEBRANTABLE — el usuario `admin` NUNCA debe tener asignado un rol.** Nunca crees un `res.users.role.line` para `base.user_admin`, ni escribas `user_ids` sobre un registro `res.users.role`. Motivo: `base_user_role.set_groups_from_roles()` REEMPLAZA los grupos de todo usuario que tenga al menos una línea de rol, dejándole únicamente los grupos implicados por sus roles. Si el admin recibe un rol, pierde de golpe `stock.group_stock_manager`, `account.group_account_manager`, `purchase.group_purchase_manager`, `sales_team.group_sale_manager` y cualquier otro grupo que tuviera fuera del rol. Los usuarios sin líneas de rol quedan intactos (`if not user.role_line_ids and not force: continue`).
   - **Cómo restringir una vista o un botón cuando el admin también debe verlo.** NUNCA uses el grupo delegado del rol (`<rol>_res_groups`) para la restricción. Crea un grupo de seguridad propio, asígnale el admin AL CREARLO, y después haz que el rol implique ese grupo:

     ```xml
     <!-- security/<modulo>_groups.xml -->
     <record id="group_stock_transfer_validation" model="res.groups">
         <field name="name">Validate Transfers</field>
         <field name="user_ids" eval="[(4, ref('base.user_admin'))]" />
     </record>
     ```

     ```xml
     <!-- data/res_users_role_data.xml -->
     <record id="role_inventory_user" model="res.users.role">
         <field name="name">Role: Inventory User</field>
         <field
             name="implied_ids"
             eval="[(4, ref('stock.group_stock_user')), (4, ref('<modulo>.group_stock_transfer_validation'))]"
         />
     </record>
     ```

     Y en la vista: `groups="<modulo>.group_stock_transfer_validation"`. El archivo de grupos DEBE ir antes que el de roles en la lista `data` del manifest. Así el admin tiene el grupo de forma directa (sin rol, por lo que `base_user_role` no lo toca) y los usuarios del rol lo reciben por implicación.
   - **NO intentes asignar el grupo desde el usuario** con `<record id="base.user_admin" model="res.users">`: la data de `base.user_admin` vive en `odoo/addons/base/data/res_users_data.xml` dentro de un `<data noupdate="1">`, así que Odoo SALTA la actualización en silencio, sin error, y el grupo nunca se asigna. Ese `noupdate` es correcto y no debe tocarse: el registro define `password`, `company_id` y `group_ids eval="[Command.set([])]"`, de modo que sin él cada `-u base` restablecería la contraseña del admin y le borraría todos los grupos.
   - Si se pide agregar un rol del módulo `base_user_role`, propón siempre crear un usuario en data demo con el rol definido y asignado, para que sirva para verificar el funcionamiento del rol. El nombre de usuario y contraseña deben coincidir (ej. `login='salesman'`, `password='salesman'`).
   - El registro `res.users` generado en data demo DEBE incluir el atributo `context="{'no_reset_password': True}"` para evitar errores del linter (`xml-create-user-wo-reset-password`).
   - Al usar roles en vistas XML con el atributo `groups="..."`, recuerda que `res.users.role` usa delegación (`_inherits`) hacia `res.groups`. Por lo tanto, el external ID del grupo generado automáticamente es `<xml_id_del_rol>_res_groups`. Si el rol es `mafensa_security.role_inventory_user`, en la vista debes usar `groups="mafensa_security.role_inventory_user_res_groups"`.

11. **Merge Requests and Task IDs:**
    - Antes de generar o sugerir la creación de un Merge Request, PREGUNTA siempre en qué tarea se está trabajando.
    - Antes de crear o actualizar un MR/PR, pasar la compuerta de pre-commit de la regla 3 sobre el HEAD que se va a pushear. Sin eso no se crea el MR.
    - El título del Merge Request DEBE incluir el prefijo `task#<ID>` (por ejemplo, `task#31865`). Esto es vital porque existe un módulo que monitorea los títulos para mapear los MRs con tareas específicas en Odoo.
    - **Ligas a PR/MR:** en descripciones y comentarios de GitLab (git.jarsa.com), en el chatter de Odoo y en los mensajes al usuario, las referencias a PR de GitHub van SIEMPRE con URL completa (`https://github.com/OCA/account-payment/pull/976`). La forma corta `OCA/account-payment#976` GitLab la convierte en liga a git.jarsa.com.
    - **Idioma de PRs/MRs:** NUNCA escribas comentarios, descripciones ni títulos de Pull Requests / Merge Requests en español. Siempre en inglés, sin importar el repo (OCA, Jarsa, etc.). Esto aplica a comentarios de revisión, cuerpos de PR y mensajes de commit. (La regla de responder en español de México es solo para la conversación con el usuario, no para artefactos de Git/GitHub.)

12. **Branch Naming:**
    - Los nombres de las ramas (branches) DEBEN ser hostnames válidos (RFC 1123). Solo pueden incluir caracteres alfanuméricos, guiones (`-`), puntos (`.`) y guiones bajos (`_`). Nunca uses caracteres especiales como `#`. Por ejemplo, usa `19.0-task-31865` en lugar de `19.0-task#31865`.
    - **REGLA INVIOLABLE — Remotos Jarsa vs Jarsa-dev:** NUNCA, bajo ninguna circunstancia, crear o pushear branches de trabajo a los remotos `Jarsa` (git.vauxoo.com:Jarsa/*, github.com:Jarsa/*). En los remotos Jarsa SOLO deben existir los branches estables por versión de Odoo (ej. `17.0` en mtnmx). TODO branch de trabajo (features, fixes, tareas) va SIEMPRE al remoto `jarsa-dev` (Jarsa-dev/*), y los pipelines de CI (incluido `odoo_sh_deploy`) se disparan en el proyecto de Jarsa-dev (ej. `glab ci run -b <branch> -R git.vauxoo.com/Jarsa-dev/<repo>`). Si un branch de trabajo llega por error a un remoto Jarsa, borrarlo de inmediato (`git push jarsa --delete <branch>`).

13. **Repository Naming:**
    - Los nombres de los REPOSITORIOS (git.jarsa.com, GitHub, etc.) NUNCA usan guion bajo (`_`); SIEMPRE usan guion (`-`), siguiendo la convención OCA (ej. `quality-control-webcam`, `stock-logistics-warehouse`). Esto contrasta con los MÓDULOS de Odoo, cuyo nombre de carpeta y `MAIN_APP` SÍ usan guion bajo porque son paquetes de Python (ej. módulo `quality_control_webcam` dentro del repo `quality-control-webcam`). La misma regla de guiones aplica al nombre de la imagen de contenedor en `DOCKER_IMAGE_REPO`.

14. **Module Migration Between Odoo Versions:**
    - Toda migración de un módulo de Odoo de una versión a otra (ej. 16.0→19.0, 18.0→19.0) DEBE hacerse con `oca-port`, sin importar si el módulo es de OCA o privado.
    - **La herramienta instalada en esta máquina es el fork `oca-port-jarsa`** (pipx, paquete `oca-port-jarsa`), que expone los binarios `oca-port` y `oca-port-jarsa`. Tiene la misma funcionalidad que el oca-port original PERO además es compatible con repositorios de GitLab (git.jarsa.com). NUNCA instales el `oca-port` original de PyPI: con repos de GitLab falla. Si el binario no está disponible, instala el fork con `pipx install oca-port-jarsa`, jamás `pipx install oca-port`.
    - Patrón: `oca-port <remote>/<origen> <remote>/<destino> <modulo> --fetch [--no-cache]` desde la raíz del repo. Para repos privados en git.jarsa.com (GitLab) usar `--platform gitlab` y/o `--upstream-org` según aplique.
    - NUNCA migrar copiando carpetas a mano ni con `git format-patch` manual: oca-port preserva el historial de commits y sigue el flujo OCA (branch `XX.0-mig-<modulo>`, commit `[MIG]`).
    - Después de oca-port, adaptar el código a la versión destino, correr pre-commit (regla 3) y validar con tests (regla 6).

15. **Sincronización de forks Jarsa con OCA — REGLA GRAVE (riesgo de perder cambios):**
    - Un fork `Jarsa/<repo>` en su rama `<version>` debe verse SIEMPRE como la historia de OCA tal cual y, encima, los commits propios de Jarsa, lineales y sin merge commits.
    - NUNCA `git merge oca/<version>` sobre la rama de Jarsa: deja los cambios de OCA DESPUÉS de los de Jarsa y llena la historia de merges, y con el tiempo ya no se sabe dónde quedó cada cambio. NUNCA resetear la rama de Jarsa a OCA a secas: se pierden los commits de Jarsa.
    - Procedimiento único cuando pidan "sincroniza <repo> con OCA":
      1. `git fetch oca <v> && git fetch jarsa <v>`
      2. `old=$(git rev-parse jarsa/<v>); base=$(git merge-base $old oca/<v>)`
      3. `git checkout -b <v>-jarsa-on-oca $old && git rebase --onto oca/<v> $base` (los merge commits viejos se descartan, los commits reales se replayan).
      4. VERIFICAR que no se perdió nada: `files=$(git diff --name-only $base $old)` y `git diff --stat $old HEAD -- $files` debe quedar VACÍO (mismo contenido en todo lo que tocó Jarsa). Si no queda vacío, revisar a mano antes de seguir.
      5. Push a `Jarsa-dev` y PR a `Jarsa/<repo>` rama `<v>`, a mezclar con "Rebase and merge". Nunca push directo a `Jarsa/*` (regla 12).
    - Lo mismo para ramas de PR que haya que actualizar: rebase y `push -f`, nunca merge commits.
    - PR a OCA y a Jarsa del mismo módulo: si difieren (por ejemplo `test-requirements.txt` con dependencias no publicadas, que va SOLO en el PR a OCA), usar ramas separadas; la de Jarsa rebaseada sobre `jarsa/<v>`.

16. **`oca_dependencies.txt` de los repos de cliente:**
    - Apunta SIEMPRE a los repos principales (`git@github.com:Jarsa/<repo>.git`, rama por defecto de la versión). Nunca a `Jarsa-dev` ni a una rama de trabajo, aunque el CI del cliente quede en rojo mientras se mezcla el PR al fork. El orden es: PR a OCA + PR al fork de Jarsa, se mezcla en el fork, y el CI del cliente se pone verde solo.
    - El CI de Jarsa (`jarsa_sync_deps`) cachea cada dependencia por nombre en un directorio persistente y solo hace `fetch` del remoto original: cambiar la URL de un repo ya cacheado falla con "couldn't find remote ref". Otra razón para no tocar las URLs.

17. **PRs a OCA y amxodoo — política de IA y versión del manifest:**
    - Aplica a todo commit/PR cuyo destino sea un repo de `github.com/OCA/*` o de `github.com/amxodoo/*` (amxodoo, la Asociación Mexicana de Odoo, es filial de OCA y sigue sus mismas reglas de mensajes de commit, autoría y versión), aunque el branch viva en `Jarsa-dev`. Política: https://github.com/OCA/.github/blob/master/AI_POLICY.md
    - **NUNCA `Co-Authored-By:` de una IA** en el commit (OCA lo prohíbe: la autoría de una IA es legalmente indefinida). Esto ANULA la atribución por defecto de Claude Code. En su lugar, trailer `Assisted-by: <modelo>` (ej. `Assisted-by: Claude Fable 5.1`), una línea por modelo/agente, sin líneas en blanco entre ellas. Tampoco `Claude-Session:` ni ligas a sesiones de claude.ai.
    - En la descripción del PR: declarar el uso de IA con la misma línea `Assisted-by: <modelo>`; NO poner `🤖 Generated with [Claude Code]` ni la liga de la sesión. El título no lleva mención de IA.
    - Antes de pushear, verificar: `git log oca/<v>..HEAD --format=%B | grep -i -E "co-authored-by:.*(claude|anthropic|copilot|gpt)|claude-session"` debe salir VACÍO.
    - **NO subir la versión en `__manifest__.py` a mano**: el bot de OCA la incrementa al mezclar (`/ocabot merge patch|minor|major`). Única excepción: commits `[MIG]` (versión `<v>.1.0.0`) o cuando se agrega un script de migración que requiere ese número de versión.
    - El resto de la política también obliga: el humano debe poder explicar y defender cada línea; a los comentarios de revisión se responde con argumentos, no regenerando el código y resubiendo; no publicar reviews ni resúmenes generados por IA sin verificarlos; PRs chicos (referencia: <500 líneas) y máximo 5 PRs o 10 reviews en 24 h por persona.

18. **SSH a servidores de Odoo.sh — SIEMPRE vía el bastión 192.99.15.215:**
    - Odoo.sh tiene un firewall que solo acepta SSH desde la IP `192.99.15.215`. Toda conexión a producción, staging o dev de cualquier cliente en Odoo.sh se hace con `ssh -J ubuntu@192.99.15.215 <build>@<host>` (hosts `<proyecto>.odoo.com` y `<proyecto>-<rama>-<build>.dev.odoo.com`). `~/.ssh/config` trae `Host *.odoo.com` con `ProxyJump ubuntu@192.99.15.215`, así que `ssh <build>@<host>` directo funciona; un timeout en el puerto 22 significa que falta ese bloque, no que el build esté dormido.
    - Archivos: `ssh <host> 'cat > /tmp/x.py' < local.py` (scp no funciona en Odoo.sh); scripts con `odoo-bin shell --no-http < /tmp/x.py`.
    - Solo configuración en bases de cliente (rutas, tipos de operación, ubicaciones, automatizaciones, permisos). Nunca crear registros operativos del cliente (máximos/mínimos, productos, proveedores, inventarios).
19. **Traducciones (`.pot` / `es.po`) — se regeneran con Odoo, nunca a mano (Odoo 16+, verificado en 19.0):**
    - Prohibido editar `msgid`/`msgstr` con scripts o a mano: el hook `oca-checks-po` del CI exige el orden/formato del exportador y las entradas quedan desfasadas. Flujo: capturar la traducción nueva en el `es.po` existente SOLO si ya existe el término (o en la BD), y luego exportar.
    - Exportar desde una BD con el módulo instalado y es_MX activo (`-i <modulo> --load-language=es_MX`). Sintaxis 19.0 (`--addons-path` va ANTES del subcomando `i18n`):
      `odoo-bin --addons-path=... i18n export -c <conf> -d <db> -o <modulo>/i18n/<modulo>.pot <modulo>` (sin `-l` = plantilla) y
      `odoo-bin --addons-path=... i18n export -c <conf> -d <db> -l es_MX -o /tmp/es.po <modulo>` y luego copiar a `i18n/es.po`.
    - **TRAMPA 1 — exportar `-o` encima de `i18n/es.po` pierde las traducciones de código:** el exportador trunca el archivo de salida antes de leer las traducciones de `_()`/JS, que NO viven en la BD sino en ese mismo `.po`. Siempre exportar a una ruta temporal y después copiar.
    - **TRAMPA 2 — el `.pot` manda:** `PoFileReader` fusiona cada `.po` con el `.pot` del módulo (`polib.merge`) y descarta las entradas cuyo `msgid` no está en el `.pot`. Con un `.pot` desactualizado, al instalar/actualizar se pierden traducciones que sí están en `es.po` (grupos, campos, términos de código). Regenerar SIEMPRE el `.pot` primero y en el mismo MR que toque términos traducibles.
    - Si la BD ya se instaló con el `.pot` viejo, recargar: `env["ir.module.module"]._load_module_terms(["<modulo>"], ["es_MX"], overwrite=True)` + `env.cr.commit()` en `odoo-bin shell`, y después exportar. `es.po` se carga para es_MX (base langs `es`, `es_419`), no hace falta `es_MX.po`.
    - Cambiar el valor en inglés de un registro (p. ej. `name` de un `res.groups`) NO reemplaza la traducción existente en la BD del cliente y `-u` tampoco (solo rellena idiomas vacíos). Si se quiere que el nuevo español se aplique, va una pre-migración que deje solo `en_US` en el jsonb (`UPDATE ... SET name = jsonb_build_object('en_US', name->>'en_US')`), como en `bylack_security/migrations/19.0.1.16.0` y `19.0.1.27.0`.
20. **Ramas de trabajo en `jarsa-dev`: rebase + force push, nunca commits de merge:**
    - Para actualizar un MR (propio o de un compañero) contra la rama estable: `git rebase jarsa/<v>` (resolver conflictos ahí) y `git push --force-with-lease jarsa-dev <rama>`. En los remotos `jarsa-dev` (Jarsa-dev/*) el force push SIEMPRE está permitido; no pedir confirmación ni buscar alternativas.
    - Prohibido "evitar el force push" metiendo `Merge branch '<v>' into <rama>` o commits extra de corrección encima del commit original: el MR debe quedar con su historia limpia (idealmente un commit por cambio). Si un compañero tiene varios commits, respetar los suyos, pero las correcciones propias se hacen con `--amend`/`fixup` + rebase, no apilando commits.
    - Razón (Alan, 3-nov-2026): en el MR !123 de bylack se bloqueó un force push y se intentó un merge de 19.0 + commit extra; Alan lo rechazó: "en los remotos jarsa-dev siempre puedes hacer force push ... no estar haciendo commits en MR de desarrollo".
