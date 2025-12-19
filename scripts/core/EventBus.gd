extends Node
class_name EventBus
# Autoload: EventBus1 -> res://scripts/core/EventBus.gd

# -------------------------------------------------------------------
# EventBus1 – stabil mag
# - Klasszikus signalok (kompatibilitás)
# - + 1 generikus csatorna: bus(topic, payload)
# -------------------------------------------------------------------

# --- Generic bus (API v1.0) ---
signal bus_emitted(topic: String, payload: Dictionary)

# --- Game / Mode ---
signal game_mode_changed(mode: String)
signal request_set_game_mode(mode: String)

# --- UI Requests ---
signal request_close_all_popups()
signal request_show_interaction_prompt(show: bool, text: String)

# --- Input / Interaction ---
signal request_interact()

# --- Encounter Flow ---
signal request_show_encounter(encounter_id: String)
signal encounter_resolved(encounter_id: String, choice_id: String)

# --- Notifications ---
signal notification_requested(text: String)

# --- Input Lock (modal hard stop) ---
signal request_set_input_locked(locked: bool, reason: String)

# -------------------------------------------------------------------
# Generic bus helper
# -------------------------------------------------------------------
func bus(topic: String, payload: Dictionary = {}) -> void:
	emit_signal("bus_emitted", str(topic), payload if payload != null else {})

# -------------------------------------------------------------------
# Thin wrappers
# -------------------------------------------------------------------
func emit_request_close_all_popups() -> void:
	emit_signal("request_close_all_popups")

func emit_request_show_interaction_prompt(show: bool, text: String) -> void:
	emit_signal("request_show_interaction_prompt", show, text)

func emit_request_interact() -> void:
	emit_signal("request_interact")

func emit_request_set_game_mode(mode: String) -> void:
	emit_signal("request_set_game_mode", mode)

func emit_game_mode_changed(mode: String) -> void:
	emit_signal("game_mode_changed", mode)

func emit_notification_requested(text: String) -> void:
	emit_signal("notification_requested", text)

func emit_request_show_encounter(encounter_id: String) -> void:
	emit_signal("request_show_encounter", encounter_id)

func emit_encounter_resolved(encounter_id: String, choice_id: String) -> void:
	emit_signal("encounter_resolved", encounter_id, choice_id)

func emit_request_set_input_locked(locked: bool, reason: String = "") -> void:
	emit_signal("request_set_input_locked", locked, reason)
