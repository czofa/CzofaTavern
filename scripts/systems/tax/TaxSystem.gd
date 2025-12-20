extends Node
class_name TaxSystem
# Autoload: TaxSystem1

@export var debug_toast: bool = true

const DEFAULT_VAT_RATE := 0.27
const PERIOD_LENGTH_DAYS := 7
const AUDIT_BASE_CHANCE := 0.1
const AUDIT_RISK_SCALE := 0.01
const AUDIT_FINE_AMOUNT := 8000
const UNPAID_VAT_FINE := 5000

var VAT_RATES: Dictionary = {
	"beer": 0.27,
	"bread": 0.18,
	"sausage": 0.27,
	"default": DEFAULT_VAT_RATE
}

var input_vat_total: int = 0
var output_vat_total: int = 0
var net_sales_total: int = 0
var net_purchases_total: int = 0
var _days_elapsed: int = 0
var _recent_stock_issue: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _period_due_notified: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_connect_bus()
	if debug_toast:
		_notify("Adó modul készen áll")

func record_purchase(item_id: String, gross_total: int) -> void:
	var osszeg: int = int(gross_total)
	if osszeg <= 0:
		return
	var bontas: Dictionary = _calc_vat_parts(item_id, osszeg)
	net_purchases_total += int(bontas.get("net", 0))
	input_vat_total += int(bontas.get("vat", 0))
	_emit_updated("purchase", item_id, osszeg)

func record_sale(item_id: String, gross_total: int) -> void:
	var osszeg: int = int(gross_total)
	if osszeg <= 0:
		return
	var bontas: Dictionary = _calc_vat_parts(item_id, osszeg)
	net_sales_total += int(bontas.get("net", 0))
	output_vat_total += int(bontas.get("vat", 0))
	_emit_updated("sale", item_id, osszeg)

func report_stock_issue(item_id: String, qty: int) -> void:
	_recent_stock_issue = true
	_apply_risk(1, "Készleteltérés jelzés: %s (%d)" % [item_id, int(qty)])

func get_summary() -> Dictionary:
	return {
		"input_vat_total": input_vat_total,
		"output_vat_total": output_vat_total,
		"net_sales_total": net_sales_total,
		"net_purchases_total": net_purchases_total,
		"vat_payable": _calc_payable_vat(),
		"vat_refund": _calc_refund_vat(),
		"days_elapsed": _days_elapsed,
		"days_left": max(PERIOD_LENGTH_DAYS - _days_elapsed, 0),
		"company_money_ft": _get_company_money(),
		"personal_money_ft": _get_personal_money()
	}

func pay_due_vat() -> Dictionary:
	var eredmeny: Dictionary = {
		"success": false,
		"paid": 0,
		"message": ""
	}
	var fizetendo: int = _calc_payable_vat()
	if fizetendo <= 0:
		_notify("ℹ️ Nincs fizetendő ÁFA, új időszak indul.")
		_reset_period()
		_emit_updated("pay", "", fizetendo)
		eredmeny["success"] = true
		eredmeny["message"] = "Nincs fizetendő ÁFA, a ledger nullázva."
		return eredmeny

	var cegpenz: int = _get_company_money()
	if cegpenz >= fizetendo:
		_add_company_money(-fizetendo, "ÁFA befizetés")
		_notify("✅ ÁFA befizetve: %d Ft" % fizetendo)
		_reset_period()
		eredmeny["success"] = true
		eredmeny["paid"] = fizetendo
		eredmeny["message"] = "ÁFA befizetés sikeres."
	else:
		_notify("⚠️ Nincs elég céges pénz az ÁFA befizetésére.")
		_apply_risk(5, "Elmaradt ÁFA befizetés")
		_apply_fine(UNPAID_VAT_FINE, "ÁFA késedelmi bírság")
		eredmeny["message"] = "Nincs elég fedezet, nőtt a kockázat."
	_emit_updated("pay", "", fizetendo)
	return eredmeny

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.day_end":
			_days_elapsed += 1
			_emit_updated("day_end", "", _days_elapsed)
			_maybe_close_period()
			_maybe_trigger_audit()
		"time.new_day":
			_emit_updated("new_day", "", _days_elapsed)
		_:
			pass

func _calc_vat_parts(item_id: String, gross_total: int) -> Dictionary:
	var rate: float = _get_rate(item_id)
	var bruto: int = max(int(gross_total), 0)
	var neto: int = int(round(float(bruto) / (1.0 + max(rate, 0.0))))
	var afa: int = bruto - neto
	return {
		"net": neto,
		"vat": afa,
		"rate": rate
	}

func _get_rate(item_id: String) -> float:
	var kulcs = str(item_id).strip_edges().to_lower()
	if kulcs != "" and VAT_RATES.has(kulcs):
		return float(VAT_RATES.get(kulcs, DEFAULT_VAT_RATE))
	return float(VAT_RATES.get("default", DEFAULT_VAT_RATE))

func _calc_payable_vat() -> int:
	return max(0, output_vat_total - input_vat_total)

func _calc_refund_vat() -> int:
	return max(0, input_vat_total - output_vat_total)

func _maybe_close_period() -> void:
	if _days_elapsed < PERIOD_LENGTH_DAYS:
		_period_due_notified = false
		return
	_days_elapsed = PERIOD_LENGTH_DAYS
	if _period_due_notified:
		return
	_period_due_notified = true
	_notify("ℹ️ Lezárt ÁFA időszak, ellenőrizd a befizetést.")
	_emit_updated("period_due", "", _days_elapsed)

func _reset_period() -> void:
	_days_elapsed = 0
	_recent_stock_issue = false
	_period_due_notified = false
	input_vat_total = 0
	output_vat_total = 0
	net_sales_total = 0
	net_purchases_total = 0
	_emit_updated("reset", "", 0)

func _maybe_trigger_audit() -> void:
	var esely: float = AUDIT_BASE_CHANCE
	var risk: int = _get_state_value("risk", 0)
	esely += float(risk) * AUDIT_RISK_SCALE
	if _recent_stock_issue:
		esely += 0.15
	esely = clamp(esely, 0.0, 0.95)
	var dobott: float = _rng.randf()
	if dobott <= esely:
		_futtat_audit()

func _futtat_audit() -> void:
	_notify("🚨 Audit indult, vizsgálják a készletet és a könyvelést.")
	_apply_fine(AUDIT_FINE_AMOUNT, "Audit bírság")
	_apply_risk(3, "Audit hatás")
	_recent_stock_issue = false
	_emit_updated("audit", "", AUDIT_FINE_AMOUNT)

func _apply_fine(amount: int, reason: String) -> void:
	var osszeg: int = abs(int(amount))
	if osszeg <= 0:
		return
	var penz: int = _get_company_money()
	if penz >= osszeg:
		_add_company_money(-osszeg, reason)
		_notify("⚠️ Bírság levonva: %d Ft (%s)" % [osszeg, reason])
		return
	if penz > 0:
		_add_company_money(-penz, reason)
	var hiany: int = max(osszeg - penz, 0)
	_apply_risk(2, "Bírság fedezet nélkül")
	_notify("⚠️ Bírság fedezet nélkül, hiány: %d Ft" % hiany)

func _get_company_money() -> int:
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		return int(EconomySystem1.get_money())
	var gs = _get_state()
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", "company_money_ft", 0))
	return 0

func _get_personal_money() -> int:
	var gs = _get_state()
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", "personal_money_ft", 0))
	return 0

func _add_company_money(delta: int, reason: String) -> void:
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("add_money"):
		EconomySystem1.add_money(delta, reason)
		return
	var gs = _get_state()
	if gs != null and gs.has_method("add_value"):
		gs.call("add_value", "company_money_ft", int(delta), reason)

func _apply_risk(delta: int, reason: String) -> void:
	var gs = _get_state()
	if gs != null and gs.has_method("add_value"):
		gs.call("add_value", "risk", int(delta), reason)

func _get_state_value(key: String, default_value: int) -> int:
	var gs = _get_state()
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", key, default_value))
	return default_value

func _get_state() -> Node:
	return get_tree().root.get_node_or_null("GameState1")

func _emit_updated(reason: String, item_id: String, amount: int) -> void:
	_bus("tax.updated", {
		"reason": reason,
		"item": item_id,
		"amount": amount,
		"summary": get_summary()
	})

func _notify(text: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
	elif debug_toast:
		print(text)

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload if payload != null else {})

func _eb() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("EventBus1")
