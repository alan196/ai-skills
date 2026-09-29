# Estimación y precio

Números validados por Alan en MTNMX 17→20 (sep-2026) y confirmados como estándar
para todos los clientes (29-sep-2026).

## Horas por módulo

La misma escala aplica para 1, 2 o 3 saltos: el número de versiones casi no
cambia el esfuerzo y ningún cliente está a más de 3 versiones del destino.

| Clase | Horas migración | Tamaño (líneas .py del módulo) |
|---|---|---|
| XS | 0.5 | < 100 líneas py, casi solo vistas/datos |
| S  | 1   | < 300 |
| M  | 2.5 | < 1,000 |
| L  | 5   | < 3,000 |
| XL | 8   | ≥ 3,000 o lógica contable crítica |

Además de esas horas:
- Tests: 0.3 h por cada 100 líneas sin cobertura, para llevar el módulo al 80 %.
  **Siempre va en la propuesta base**, solo para módulos custom del cliente y
  de Jarsa.
- Prueba funcional Jarsa: 0.25–3 h por módulo.
- Acción de servidor con código: 0.25 h cada una. Solo las de la lista que
  entregue el cliente.
- Módulo de terceros que ya está en la versión destino: solo instalar y
  probar.
- Referencia de Alan: repse_mtnmx (5.5 k líneas) = 15–20 h en total. Si la
  escala da mucho más, está inflada.

## Plan por fases (estructura del Plan de trabajo)

0. Arranque y planeación: kick-off, rama destino, CI, build en Odoo.sh.
1. Inventario y congelamiento de código.
   - Personalización sin módulo; se firma con el cliente.
   - Commit de referencia.
   - Por módulo: migrar, pasar a nativo o retirar.
2. Migración de BD con upgrade.odoo.com.
   - 1er upgrade de prueba lo antes posible, aunque sea a una versión
     intermedia, para abrir tickets con Odoo a tiempo.
   - Scripts pre/post.
   - 3 ensayos: bloque A; A+B con saldos contables origen vs destino; todo con
     tiempos medidos.
   - Lo hacen Alan y Héctor, 50/50.
3. Módulos no nativos.
   - Bloque A: terceros.
   - Bloque B: críticos contables.
   - Bloque C: operativos.
   - Revisión senior de MR.
   - Pruebas funcionales por módulo.
4. Cobertura de tests al 80 % (opcional).
5. Remediación de la personalización sin módulo.
6. Pruebas integrales por proceso (Jarsa).
7. UAT del cliente y correcciones. En MTNMX: 4 semanas, 1 líder + 6 usuarios
   clave, ≈20 h cada uno.
8. Capacitación en cambios. La contable la da Alan.
9. Arranque: fin de semana fuera de cierre de mes, más 2 semanas de soporte
   reforzado.
10. Garantía de 60 días, solo para defectos de la migración.
11. Gestión de proyecto: ≈12 % de las horas.

Contingencia: 10 %. Las actividades que no son código no deben multiplicar el
total: la migración de código es ~80 % del trabajo.

## Equipo y capacidad

La asignación cambia por cliente y depende del flujo del proyecto. Referencia
MTNMX: Alan (Senior) 30 %, Héctor Meraz 50 %, Abraham (junior) 50 %, consultor
funcional y PM Annia.

La capacidad no es el límite: con el flujo mensual se puede contratar otro
Senior (Alan ya tiene candidatos). Por eso la fecha no se recorta por falta de
gente. Si las horas no caben, proponer la asignación con un Senior contratado
adicional y su costo en el modelo interno. El arranque debe caer antes del
31/03, con al menos 6 semanas de margen.

## Precio

Precio = horas cobrables × tarifa por nivel. No es costo + margen.
- **Tarifas estándar para migraciones (vigentes desde sep-2026):** Senior
  $1,400 por hora; consultoría (desarrollo, funcional, PM) $1,285 por hora.
  Aplican a todos los clientes. Se presentan como la tarifa de migración
  vigente, sin mencionar el contrato de MTNMX.
- Horas sin cargo: módulos cubiertos por la anualidad L.M.E. Van en el plan
  con tarifa 0.
- El texto de la propuesta dice: "El importe es fijo: las horas son la base de
  cálculo, no un tope facturable."
- Cambios fuera de alcance: a la tarifa vigente del cliente por hora.

## Modelo interno (solo para Alan, nunca al cliente)

Para cada persona se calcula: sueldo, carga social e indirectos, que dan el
costo. El proyecto se evalúa con ISR/PTU, la comisión de Alan (5 %) y el costo
de IA.
- Costo de IA: ~USD 250 al mes, unos $4,300 MXN.
- Resultado de MTNMX: margen neto de 33 % con el precio por horas.

Parámetros vigentes, los mismos de MTNMX:

| Parámetro | Valor |
|---|---|
| Sueldo Héctor Meraz | $25,000 al mes |
| Sueldo Abraham (junior) | $2,000 a la semana |
| Indirectos | 30 % |
| Comisión de Alan | 5 % |
| Coeficiente de utilidad | 0.0163 |
| Margen neto objetivo | 35 % (30 % mínimo) |
| Contingencia | 10 % |

- Carga social y PTU: los mismos supuestos del modelo de MTNMX. Si no se
  tienen a mano, preguntar a Alan; no inventarlos.
- Si el margen con las tarifas estándar baja del 30 %, avisar a Alan antes de
  entregar.
