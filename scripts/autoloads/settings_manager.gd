extends Node
## SettingsManager — persists user preferences to user://settings.cfg.
## Autoload: loads settings on startup and applies them via AudioManager / DisplayServer.

const SETTINGS_PATH := "user://settings.cfg"

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	var err: Error = _config.load(SETTINGS_PATH)
	if err != OK:
		# First launch — write defaults
		_config.set_value("audio", "master_volume", 1.0)
		_config.set_value("audio", "music_volume", 0.7)
		_config.set_value("audio", "sfx_volume", 0.8)
		_config.set_value("video", "fullscreen", true)
		_save_config()

	# Apply stored settings
	_apply_all()


func get_master_volume() -> float:
	return _config.get_value("audio", "master_volume", 1.0) as float


func get_music_volume() -> float:
	return _config.get_value("audio", "music_volume", 0.7) as float


func get_sfx_volume() -> float:
	return _config.get_value("audio", "sfx_volume", 0.8) as float


func get_fullscreen() -> bool:
	return _config.get_value("video", "fullscreen", true) as bool


func set_master_volume(v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	_config.set_value("audio", "master_volume", v)
	AudioManager.set_master_volume(v)
	_save_config()


func set_music_volume(v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	_config.set_value("audio", "music_volume", v)
	AudioManager.set_music_volume(v)
	_save_config()


func set_sfx_volume(v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	_config.set_value("audio", "sfx_volume", v)
	AudioManager.set_sfx_volume(v)
	_save_config()


func set_fullscreen(b: bool) -> void:
	_config.set_value("video", "fullscreen", b)
	if b:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_config()


func save() -> void:
	_save_config()


func _apply_all() -> void:
	AudioManager.set_master_volume(get_master_volume())
	AudioManager.set_music_volume(get_music_volume())
	AudioManager.set_sfx_volume(get_sfx_volume())
	if get_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _save_config() -> void:
	var err: Error = _config.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: failed to save config: %s" % error_string(err))
