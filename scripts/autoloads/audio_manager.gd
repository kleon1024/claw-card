extends Node
## AudioManager — handles music (with crossfade) and SFX (pooled players).
## Autoload: provides global audio playback for the entire game.

const SILENCE_DB := -80.0
const DEFAULT_CROSSFADE := 1.0
const SFX_POOL_SIZE := 8

var _music_players: Array[AudioStreamPlayer] = []
var _current_music_idx: int = 0
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_volume_db: float = 0.0
var _sfx_volume_db: float = 0.0


func _ready() -> void:
	# Create 2 music players for crossfade
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = _get_bus_or_default("Music")
		player.volume_db = SILENCE_DB
		add_child(player)
		_music_players.append(player)

	# Create SFX pool
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = _get_bus_or_default("SFX")
		add_child(player)
		_sfx_pool.append(player)


func play_music(stream: AudioStream, crossfade_duration: float = DEFAULT_CROSSFADE) -> void:
	if stream == null:
		push_warning("AudioManager.play_music: null stream, ignoring")
		return

	var old_idx: int = _current_music_idx
	var new_idx: int = 1 - old_idx
	_current_music_idx = new_idx

	var old_player: AudioStreamPlayer = _music_players[old_idx]
	var new_player: AudioStreamPlayer = _music_players[new_idx]

	# Set up new player
	new_player.stream = stream
	new_player.volume_db = SILENCE_DB
	new_player.play()

	# Crossfade
	var tw := create_tween().set_parallel(true)
	tw.tween_property(old_player, "volume_db", SILENCE_DB, crossfade_duration)
	tw.tween_property(new_player, "volume_db", _music_volume_db, crossfade_duration)
	await tw.finished

	# Stop old player after fade
	old_player.stop()


func stop_music(fade_out: float = 1.0) -> void:
	var player: AudioStreamPlayer = _music_players[_current_music_idx]
	if not player.playing:
		return
	var tw := create_tween()
	tw.tween_property(player, "volume_db", SILENCE_DB, fade_out)
	await tw.finished
	player.stop()


func play_sfx(stream: AudioStream, pitch_variance: float = 0.0) -> void:
	if stream == null:
		push_warning("AudioManager.play_sfx: null stream, ignoring")
		return

	var player: AudioStreamPlayer = _get_available_sfx_player()
	if player == null:
		push_warning("AudioManager.play_sfx: no available SFX player")
		return

	player.stream = stream
	player.volume_db = _sfx_volume_db
	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	else:
		player.pitch_scale = 1.0
	player.play()


func set_music_volume(linear: float) -> void:
	_music_volume_db = linear_to_db(clampf(linear, 0.0, 1.0))
	# Apply to currently playing music player
	var player: AudioStreamPlayer = _music_players[_current_music_idx]
	if player.playing:
		player.volume_db = _music_volume_db


func set_sfx_volume(linear: float) -> void:
	_sfx_volume_db = linear_to_db(clampf(linear, 0.0, 1.0))


func set_master_volume(linear: float) -> void:
	var db: float = linear_to_db(clampf(linear, 0.0, 1.0))
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, db)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null


func _get_bus_or_default(bus_name: String) -> StringName:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		return StringName(bus_name)
	return &"Master"
