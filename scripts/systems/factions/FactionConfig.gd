extends Node
class_name FactionConfig

const FACTIONS = [
	{"id": "villagers", "display_name": "Falusiak", "icon": "🧑‍🌾"},
	{"id": "authority", "display_name": "Hatóság", "icon": "🛡️"},
	{"id": "underworld", "display_name": "Alvilág", "icon": "🕶️"}
]

const DEFAULT_VALUE = 0

const STATUS_THRESHOLDS = [
	{"min": -999, "max": -3, "label": "Ellenséges", "description": "Aktívan ellened dolgoznak, figyelnek minden lépésedre."},
	{"min": -2, "max": 2, "label": "Semleges", "description": "Nem ismernek jól, kivárják, hogy hová billen a mérleg."},
	{"min": 3, "max": 999, "label": "Barátságos", "description": "Segítőkészek és bizalmat szavaznak neked."}
]

const CHANCE_RULES = {
	"authority_audit": {
		"base": 0.35,
		"risk_scale": 0.10,
		"reputation_penalty": 0.06,
		"authority_penalty": 0.05,
		"max_chance": 0.90
	},
	"underworld_offer": {
		"base": 0.32,
		"risk_scale": 0.12,
		"negative_reputation_bonus": 0.05,
		"authority_mistrust_bonus": 0.05,
		"max_chance": 0.90
	}
}

const EVENT_DEFINITIONS = {
	"authority_audit": {
		"encounter_id": "test_taxman",
		"notification": "📋 A hatóság auditot fontolgat..."
	},
	"underworld_offer": {
		"encounter_id": "test_underworld",
		"notification": "🕶️ Az alvilág ajánlata érkezett..."
	}
}

static func get_status_data(value: int) -> Dictionary:
	for t in STATUS_THRESHOLDS:
		var min_v = int(t.get("min", -999))
		var max_v = int(t.get("max", 999))
		if value >= min_v and value <= max_v:
			return {
				"label": str(t.get("label", "")),
				"description": str(t.get("description", ""))
			}
	return {"label": "Semleges", "description": ""}

static func clamp_chance(value: float, max_value: float) -> float:
	return clamp(value, 0.0, max_value)
