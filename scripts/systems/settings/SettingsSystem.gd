extends Node
class_name SettingsSystem
# Autoload neve: SettingsSystem1

const CONFIG_PATH = "user://settings.cfg"

var adatok: Dictionary = {
	"fullscreen": false,
	"master_volume": 1.0,
	"mouse_sensitivity": 1.0,
	"invert_y": false
}

func _ready() -> void:
	load_settings()
	apply_settings()

func get_setting(kulcs: String, alapertelmezett: Variant = null) -> Variant:
	if adatok.has(kulcs):
		return adatok[kulcs]
	return alapertelmezett

func set_setting(kulcs: String, ertek: Variant) -> void:
	adatok[kulcs] = ertek

func load_settings() -> void:
	var cfg = ConfigFile.new()
	var eredmeny = cfg.load(CONFIG_PATH)
	if eredmeny != OK:
		save_settings()
		return
	adatok["fullscreen"] = bool(cfg.get_value("display", "fullscreen", adatok.get("fullscreen", false)))
	adatok["master_volume"] = float(cfg.get_value("audio", "master_volume", adatok.get("master_volume", 1.0)))
	adatok["mouse_sensitivity"] = float(cfg.get_value("input", "mouse_sensitivity", adatok.get("mouse_sensitivity", 1.0)))
	adatok["invert_y"] = bool(cfg.get_value("input", "invert_y", adatok.get("invert_y", false)))

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("display", "fullscreen", bool(adatok.get("fullscreen", false)))
	cfg.set_value("audio", "master_volume", float(adatok.get("master_volume", 1.0)))
	cfg.set_value("input", "mouse_sensitivity", float(adatok.get("mouse_sensitivity", 1.0)))
	cfg.set_value("input", "invert_y", bool(adatok.get("invert_y", false)))
	var eredmeny = cfg.save(CONFIG_PATH)
	if eredmeny != OK:
		print("[Settings] ❌ Nem sikerült menteni: %s" % CONFIG_PATH)
	else:
		print("[Settings] ✅ Mentve: %s" % CONFIG_PATH)

func apply_settings() -> void:
	_apply_fullscreen()
	_apply_volume()

func _apply_fullscreen() -> void:
	var full = bool(adatok.get("fullscreen", false))
	if full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_volume() -> void:
	var vol = float(adatok.get("master_volume", 1.0))
	var linear = clamp(vol, 0.0, 1.0)
	var db = -80.0
	if linear > 0.0:
		db = linear_to_db(linear)
	var bus = AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, db)

func apply_mouse_settings() -> void:
	# Jelenleg csak tárolás, az FPS controller később használja
	pass
