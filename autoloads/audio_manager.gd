extends Node

## Audio manager with procedural music/SFX, volume control, crossfade, and SFX pooling.

enum MusicTrack { MENU, OVERWORLD, BATTLE, TRAINER_BATTLE, VICTORY, EVOLUTION, SHOP, CHAMPION }
enum SFX {
	BUTTON_CLICK, MENU_OPEN, MENU_CLOSE,
	ATTACK_HIT, SUPER_EFFECTIVE, NOT_EFFECTIVE, MISS, FAINT,
	STEP, PORTAL_ENTER, NPC_INTERACT,
	USE_POTION, BALL_THROW, CAPTURE_SUCCESS, CAPTURE_FAIL,
	EVOLVE_SPARKLE, EVOLVE_COMPLETE, LEVEL_UP, BADGE_EARN,
	TRADE_OFFER, TRADE_COMPLETE, PVP_WIN, PVP_LOSE,
}

const SFX_POOL_SIZE := 4
const FADE_DURATION := 0.8

var music_volume: float = 0.6:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		_apply_music_volume()
var sfx_volume: float = 0.7:
	set(v):
		sfx_volume = clampf(v, 0.0, 1.0)
		_apply_sfx_volume()

var _current_track: int = -1
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer  # Points to A or B
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

func _ready() -> void:
	# Create two music players for crossfade
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = "Master"
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = "Master"
	_music_player_b.volume_db = -80.0
	add_child(_music_player_b)

	_active_player = _music_player_a

	# Create SFX pool
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)

	_apply_music_volume()
	_apply_sfx_volume()

func play_track(track: MusicTrack) -> void:
	if track == _current_track:
		return
	_current_track = track
	var stream: AudioStreamWAV = MusicLibrary.get_track(track)
	if not stream:
		return
	_fade_to(stream)

func play_sound(sfx: SFX) -> void:
	var stream: AudioStreamWAV = SfxLibrary.get_sfx(sfx)
	if not stream:
		return
	var player := _sfx_pool[_sfx_pool_index]
	player.stream = stream
	player.play()
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE

func stop_music() -> void:
	_current_track = -1
	_music_player_a.stop()
	_music_player_b.stop()

func set_music_volume(v: float) -> void:
	music_volume = v

func set_sfx_volume(v: float) -> void:
	sfx_volume = v

# Legacy compat
func play_music(stream: AudioStream) -> void:
	if stream:
		_fade_to(stream)

func play_sfx(stream: AudioStream) -> void:
	if stream:
		var player := _sfx_pool[_sfx_pool_index]
		player.stream = stream
		player.play()
		_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE

func _fade_to(stream: AudioStream) -> void:
	var old_player := _active_player
	var new_player := _music_player_b if _active_player == _music_player_a else _music_player_a
	_active_player = new_player

	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()

	var tween := create_tween()
	tween.set_parallel(true)
	var target_db := linear_to_db(music_volume)
	tween.tween_property(new_player, "volume_db", target_db, FADE_DURATION)
	tween.tween_property(old_player, "volume_db", -80.0, FADE_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(func(): old_player.stop())

func _apply_music_volume() -> void:
	if _active_player:
		_active_player.volume_db = linear_to_db(music_volume)

func _apply_sfx_volume() -> void:
	for p in _sfx_pool:
		p.volume_db = linear_to_db(sfx_volume)
