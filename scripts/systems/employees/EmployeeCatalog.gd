extends Node
# Alap alkalmazotti katalógus és járulék presetek

const STARTER_HELPER_DAYS_FREE = 3
const DEFAULT_PAYROLL_PRESET = "mvp_basic"
const DEFAULT_GROSS_AFTER_FREE = 120000

var payroll_presets = {
	"mvp_basic": {
		"label": "Alap járulék csomag",
		"employer_contrib_rate": 0.17,
		"health_rate": 0.07
	}
}

var default_employees = [
	{
		"id": "best_friend",
		"name": "Legjobb barát",
		"speed": 2,
		"cook": 1,
		"reliability": 3,
		"shift_start": 6 * 60,
		"shift_end": 22 * 60,
		"free_days": STARTER_HELPER_DAYS_FREE,
		"payroll_preset": DEFAULT_PAYROLL_PRESET,
		"gross": 0
	}
]
