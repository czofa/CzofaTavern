extends Control

const DebugFlags = preload("res://scripts/core/DebugFlags.gd")

@export var new_game_button_path: NodePath = ^"Margin/VBox/MenuButtons/NewGameButton"
@export var continue_button_path: NodePath = ^"Margin/VBox/MenuButtons/ContinueButton"
@export var settings_button_path: NodePath = ^"Margin/VBox/MenuButtons/SettingsButton"
@export var exit_button_path: NodePath = ^"Margin/VBox/MenuButtons/ExitButton"
@export var admin_button_path: NodePath = ^"Margin/VBox/MenuButtons/AdminButton"
@export var status_label_path: NodePath = ^"Margin/VBox/StatusLabel"

@export var settings_panel_path: NodePath = ^"SettingsPanel"
@export var settings_fullscreen_path: NodePath = ^"SettingsPanel/Panel/VBox/Fullscreen"
@export var settings_volume_path: NodePath = ^"SettingsPanel/Panel/VBox/VolumeHBox/VolumeSlider"
@export var settings_volume_label_path: NodePath = ^"SettingsPanel/Panel/VBox/VolumeHBox/VolumeValue"
@export var settings_sens_path: NodePath = ^"SettingsPanel/Panel/VBox/SensHBox/SensSlider"
@export var settings_sens_label_path: NodePath = ^"SettingsPanel/Panel/VBox/SensHBox/SensValue"
@export var settings_invert_path: NodePath = ^"SettingsPanel/Panel/VBox/InvertY"
@export var settings_save_button_path: NodePath = ^"SettingsPanel/Panel/VBox/SaveSettings"
@export var settings_close_button_path: NodePath = ^"SettingsPanel/Panel/VBox/CloseSettings"

@export var admin_panel_path: NodePath = ^"AdminPanel"
@export var main_scene_path: String = "res://scenes/main/Main.tscn"
@export var continue_save_path: String = "user://savegame.json"

var _btn_new_game: Button
var _btn_continue: Button
var _btn_settings: Button
var _btn_exit: Button
var _btn_admin: Button
var _status_label: Label

var _settings_panel: Control
var _settings_fullscreen: CheckBox
var _settings_volume: HSlider
var _settings_volume_label: Label
var _settings_sens: HSlider
var _settings_sens_label: Label
var _settings_invert: CheckBox
var _settings_save_button: Button
var _settings_close_button: Button
var _admin_panel: Control

func _ready() -> void:
	_cache_nodes()
	_connect_signals()
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("load_all"):
			gd.call("load_all")
	if has_node("/root/SettingsSystem1"):
		var ss = get_node("/root/SettingsSystem1")
		if ss.has_method("load_settings"):
			ss.call("load_settings")
		if ss.has_method("apply_settings"):
			ss.call("apply_settings")
	_populate_settings_ui()
	_refresh_continue_state()
	_update_admin_visibility()

func _cache_nodes() -> void:
	_btn_new_game = get_node_or_null(new_game_button_path)
	_btn_continue = get_node_or_null(continue_button_path)
	_btn_settings = get_node_or_null(settings_button_path)
	_btn_exit = get_node_or_null(exit_button_path)
	_btn_admin = get_node_or_null(admin_button_path)
	_status_label = get_node_or_null(status_label_path)
	_settings_panel = get_node_or_null(settings_panel_path)
	_settings_fullscreen = get_node_or_null(settings_fullscreen_path)
	_settings_volume = get_node_or_null(settings_volume_path)
	_settings_volume_label = get_node_or_null(settings_volume_label_path)
	_settings_sens = get_node_or_null(settings_sens_path)
	_settings_sens_label = get_node_or_null(settings_sens_label_path)
	_settings_invert = get_node_or_null(settings_invert_path)
	_settings_save_button = get_node_or_null(settings_save_button_path)
	_settings_close_button = get_node_or_null(settings_close_button_path)
	_admin_panel = get_node_or_null(admin_panel_path)

func _connect_signals() -> void:
	if _btn_new_game != null:
		_btn_new_game.pressed.connect(_on_new_game)
	if _btn_continue != null:
		_btn_continue.pressed.connect(_on_continue)
	if _btn_settings != null:
		_btn_settings.pressed.connect(_toggle_settings)
	if _btn_exit != null:
		_btn_exit.pressed.connect(_on_exit)
	if _btn_admin != null:
		_btn_admin.pressed.connect(_open_admin)
	if _settings_save_button != null:
		_settings_save_button.pressed.connect(_on_settings_save)
	if _settings_close_button != null:
		_settings_close_button.pressed.connect(_toggle_settings)
	if _settings_volume != null:
		_settings_volume.value_changed.connect(_on_volume_changed)
	if _settings_sens != null:
		_settings_sens.value_changed.connect(_on_sens_changed)

func _on_new_game() -> void:
	_refresh_continue_state()
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("load_all"):
			gd.call("load_all")
	_go_to_main_scene()

func _on_continue() -> void:
	if not FileAccess.file_exists(continue_save_path):
		_status("⚠️ Nincs mentés, a gomb tiltva.")
		_refresh_continue_state()
		return
	_go_to_main_scene()

func _go_to_main_scene() -> void:
	var path = main_scene_path.strip_edges()
	if path == "":
		_status("❌ Nincs beállított fő jelenet.")
		return
	var err = get_tree().change_scene_to_file(path)
	if err != OK:
		_status("❌ Nem sikerült betölteni a fő jelenetet.")

func _toggle_settings() -> void:
	if _settings_panel == null:
		return
	_settings_panel.visible = not _settings_panel.visible
	if _settings_panel.visible:
		_populate_settings_ui()

func _on_exit() -> void:
	get_tree().quit()

func _open_admin() -> void:
	if _admin_panel == null:
		_status("ℹ️ Admin panel nem érhető el.")
		return
	_admin_panel.visible = true
	if _admin_panel.has_method("open_panel"):
		_admin_panel.call("open_panel")

func _refresh_continue_state() -> void:
	if _btn_continue == null:
		return
	_btn_continue.disabled = not FileAccess.file_exists(continue_save_path)

func _populate_settings_ui() -> void:
	var ss = get_node_or_null("/root/SettingsSystem1")
	if ss == null:
		return
	var full = ss.call("get_setting", "fullscreen", false) if ss.has_method("get_setting") else false
	var vol = ss.call("get_setting", "master_volume", 1.0) if ss.has_method("get_setting") else 1.0
	var sens = ss.call("get_setting", "mouse_sensitivity", 1.0) if ss.has_method("get_setting") else 1.0
	var inv = ss.call("get_setting", "invert_y", false) if ss.has_method("get_setting") else false
	if _settings_fullscreen is CheckBox:
		_settings_fullscreen.button_pressed = bool(full)
	if _settings_volume is HSlider:
		_settings_volume.value = float(vol)
	_on_volume_changed(_settings_volume.value if _settings_volume is HSlider else 0.0)
	if _settings_sens is HSlider:
		_settings_sens.value = float(sens)
	_on_sens_changed(_settings_sens.value if _settings_sens is HSlider else 0.0)
	if _settings_invert is CheckBox:
		_settings_invert.button_pressed = bool(inv)

func _on_settings_save() -> void:
	var ss = get_node_or_null("/root/SettingsSystem1")
	if ss == null:
		_status("ℹ️ SettingsSystem1 nem érhető el.")
		return
	var full = bool(_settings_fullscreen.button_pressed) if _settings_fullscreen is CheckBox else false
	var vol = float(_settings_volume.value) if _settings_volume is HSlider else 1.0
	var sens = float(_settings_sens.value) if _settings_sens is HSlider else 1.0
	var inv = bool(_settings_invert.button_pressed) if _settings_invert is CheckBox else false
	if ss.has_method("set_setting"):
		ss.call("set_setting", "fullscreen", full)
		ss.call("set_setting", "master_volume", vol)
		ss.call("set_setting", "mouse_sensitivity", sens)
		ss.call("set_setting", "invert_y", inv)
	if ss.has_method("save_settings"):
		ss.call("save_settings")
	if ss.has_method("apply_settings"):
		ss.call("apply_settings")
	_status("✅ Beállítások mentve és alkalmazva.")
	if _settings_panel != null:
		_settings_panel.visible = false

func _on_volume_changed(value: float) -> void:
	if _settings_volume_label is Label:
		_settings_volume_label.text = "%.2f" % value

func _on_sens_changed(value: float) -> void:
	if _settings_sens_label is Label:
		_settings_sens_label.text = "%.2f" % value

func _update_admin_visibility() -> void:
	if _btn_admin != null:
		_btn_admin.visible = DebugFlags.ENABLE_ADMIN
	if _admin_panel != null:
		_admin_panel.visible = false

func _status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
