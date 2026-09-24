import time
from playwright.sync_api import sync_playwright
BASE = "http://localhost:8090"
OUT = "/private/tmp/claude-501/-Users-ramitos-proyectos-19-0-bylack/661912cd-76a3-492d-93af-cec633a5082a/scratchpad/shots/"
A = "/odoo/action-sale_commission_bylack."

def login(b, login):
    ctx = b.new_context(viewport={"width": 1440, "height": 900}, locale="es-MX")
    page = ctx.new_page()
    page.goto(BASE + "/web/login")
    page.fill("input[name=login]", login); page.fill("input[name=password]", login)
    page.click("form.oe_login_form button[type=submit]"); page.wait_for_selector(".o_navbar", timeout=60000)
    return page

def shot(page, url, name, wait=".o_content", after=None):
    try:
        page.goto(BASE + url); page.wait_for_selector(wait, timeout=60000); time.sleep(2.0)
        if after: after(page); time.sleep(1.0)
        page.screenshot(path=OUT + name + ".png"); print("ok", name)
    except Exception as e:
        print("FALLO", name, str(e).splitlines()[0][:120])

tab = lambda t: (lambda pg: pg.get_by_role("tab", name=t).click())
with sync_playwright() as p:
    b = p.chromium.launch()
    page = login(b, "admin")
    shot(page, A + "bylack_commission_scheme_action/1", "02_esquema", ".o_form_view")
    shot(page, A + "bylack_commission_scheme_action/1", "03_esquema_bonos", ".o_form_view", tab("Reglas de bono"))
    shot(page, A + "bylack_commission_scheme_action/1", "04_esquema_tabulador", ".o_form_view", tab("Tabulador de canceladas"))
    shot(page, "/odoo/action-account.action_move_out_invoice_type/1", "09_factura_correccion", ".o_form_view", tab("Correcciones"))
    shot(page, A + "bylack_commission_settlement_action/1", "11_liquidacion_importes", ".o_form_view")
    shot(page, A + "bylack_commission_settlement_action/1", "12_liquidacion_documentos", ".o_form_view", tab("Documentos"))
    shot(page, A + "bylack_commission_settlement_action/1", "13_liquidacion_ajustes", ".o_form_view", tab("Ajustes"))
    shot(page, A + "bylack_commission_settlement_action/6", "14_liquidacion_gerente", ".o_form_view")
    page.context.close()
    page = login(b, "magaly")
    shot(page, A + "bylack_commission_settlement_action/1", "16_aprobar_coordinadora", ".o_form_view")
    page.context.close()
    page = login(b, "adriana")
    shot(page, A + "bylack_commission_settlement_action/2", "17_autorizar_administracion", ".o_form_view")
    page.context.close()
    b.close()
