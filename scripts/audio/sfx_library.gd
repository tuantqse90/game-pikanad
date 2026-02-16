extends RefCounted
class_name SfxLibrary

## Pre-defined SFX using ToneGenerator. Short procedural sound effects
## for UI, battle, overworld, and item interactions.

# Cache generated SFX
static var _cache: Dictionary = {}

static func get_sfx(sfx_id: int) -> AudioStreamWAV:
	if _cache.has(sfx_id):
		return _cache[sfx_id]
	var stream: AudioStreamWAV = _generate_sfx(sfx_id)
	_cache[sfx_id] = stream
	return stream

static func _generate_sfx(sfx_id: int) -> AudioStreamWAV:
	match sfx_id:
		0:   return _button_click()
		1:   return _menu_open()
		2:   return _menu_close()
		3:   return _attack_hit()
		4:   return _super_effective()
		5:   return _not_effective()
		6:   return _miss()
		7:   return _faint()
		8:   return _step()
		9:   return _portal_enter()
		10:  return _npc_interact()
		11:  return _use_potion()
		12:  return _ball_throw()
		13:  return _capture_success()
		14:  return _capture_fail()
		15:  return _evolve_sparkle()
		16:  return _evolve_complete()
		17:  return _level_up()
		18:  return _badge_earn()
		19:  return _trade_offer()
		20:  return _trade_complete()
		21:  return _pvp_win()
		22:  return _pvp_lose()
	return _button_click()

# ── UI SFX ──────────────────────────────────────────────────────────────────

static func _button_click() -> AudioStreamWAV:
	return ToneGenerator.generate_tone(800.0, 0.04, ToneGenerator.WaveType.SQUARE, 0.3)

static func _menu_open() -> AudioStreamWAV:
	var notes := [
		{freq = 400.0, duration_beats = 0.15},
		{freq = 600.0, duration_beats = 0.15},
		{freq = 800.0, duration_beats = 0.2},
	]
	return ToneGenerator.generate_melody(notes, 300.0, ToneGenerator.WaveType.TRIANGLE, 0.3, false)

static func _menu_close() -> AudioStreamWAV:
	var notes := [
		{freq = 800.0, duration_beats = 0.15},
		{freq = 600.0, duration_beats = 0.15},
		{freq = 400.0, duration_beats = 0.2},
	]
	return ToneGenerator.generate_melody(notes, 300.0, ToneGenerator.WaveType.TRIANGLE, 0.3, false)

# ── Battle SFX ──────────────────────────────────────────────────────────────

static func _attack_hit() -> AudioStreamWAV:
	# Impact noise burst
	return ToneGenerator.generate_tone(150.0, 0.1, ToneGenerator.WaveType.NOISE, 0.5,
		0.005, 0.02, 0.3, 0.05)

static func _super_effective() -> AudioStreamWAV:
	# Ascending bright tone
	var notes := [
		{freq = 523.0, duration_beats = 0.2},
		{freq = 659.0, duration_beats = 0.2},
		{freq = 784.0, duration_beats = 0.2},
		{freq = 1047.0, duration_beats = 0.4},
	]
	return ToneGenerator.generate_melody(notes, 240.0, ToneGenerator.WaveType.SINE, 0.4, false)

static func _not_effective() -> AudioStreamWAV:
	# Descending dull tone
	var notes := [
		{freq = 400.0, duration_beats = 0.3},
		{freq = 300.0, duration_beats = 0.3},
		{freq = 200.0, duration_beats = 0.4},
	]
	return ToneGenerator.generate_melody(notes, 200.0, ToneGenerator.WaveType.TRIANGLE, 0.25, false)

static func _miss() -> AudioStreamWAV:
	# Quick whoosh — noise fade
	return ToneGenerator.generate_tone(200.0, 0.15, ToneGenerator.WaveType.NOISE, 0.2,
		0.01, 0.03, 0.1, 0.08)

static func _faint() -> AudioStreamWAV:
	# Sad descending tone
	var notes := [
		{freq = 440.0, duration_beats = 0.3},
		{freq = 370.0, duration_beats = 0.3},
		{freq = 300.0, duration_beats = 0.3},
		{freq = 220.0, duration_beats = 0.6},
	]
	return ToneGenerator.generate_melody(notes, 150.0, ToneGenerator.WaveType.TRIANGLE, 0.35, false)

# ── Overworld SFX ───────────────────────────────────────────────────────────

static func _step() -> AudioStreamWAV:
	# Soft tick
	return ToneGenerator.generate_tone(300.0, 0.03, ToneGenerator.WaveType.NOISE, 0.15,
		0.005, 0.01, 0.1, 0.01)

static func _portal_enter() -> AudioStreamWAV:
	# Ascending whoosh with sparkle
	var notes := [
		{freq = 300.0, duration_beats = 0.15},
		{freq = 500.0, duration_beats = 0.15},
		{freq = 700.0, duration_beats = 0.15},
		{freq = 1000.0, duration_beats = 0.2},
		{freq = 1200.0, duration_beats = 0.3},
	]
	return ToneGenerator.generate_melody(notes, 250.0, ToneGenerator.WaveType.SINE, 0.3, false)

static func _npc_interact() -> AudioStreamWAV:
	# Short chirp
	var notes := [
		{freq = 600.0, duration_beats = 0.1},
		{freq = 800.0, duration_beats = 0.15},
	]
	return ToneGenerator.generate_melody(notes, 300.0, ToneGenerator.WaveType.SQUARE, 0.2, false)

# ── Item SFX ────────────────────────────────────────────────────────────────

static func _use_potion() -> AudioStreamWAV:
	# Heal ascending arpeggio
	var notes := [
		{freq = 523.0, duration_beats = 0.15},
		{freq = 659.0, duration_beats = 0.15},
		{freq = 784.0, duration_beats = 0.15},
		{freq = 1047.0, duration_beats = 0.3},
	]
	return ToneGenerator.generate_melody(notes, 280.0, ToneGenerator.WaveType.SINE, 0.3, false)

static func _ball_throw() -> AudioStreamWAV:
	# Whoosh ascending
	var notes := [
		{freq = 200.0, duration_beats = 0.1, wave = ToneGenerator.WaveType.NOISE},
		{freq = 400.0, duration_beats = 0.1},
		{freq = 600.0, duration_beats = 0.15},
	]
	return ToneGenerator.generate_melody(notes, 300.0, ToneGenerator.WaveType.TRIANGLE, 0.3, false)

static func _capture_success() -> AudioStreamWAV:
	# Triumphant jingle
	var notes := [
		{freq = 523.0, duration_beats = 0.2},
		{freq = 659.0, duration_beats = 0.2},
		{freq = 784.0, duration_beats = 0.2},
		{freq = 1047.0, duration_beats = 0.6},
	]
	return ToneGenerator.generate_melody(notes, 200.0, ToneGenerator.WaveType.TRIANGLE, 0.35, false)

static func _capture_fail() -> AudioStreamWAV:
	# Descending buzz
	var notes := [
		{freq = 300.0, duration_beats = 0.15},
		{freq = 200.0, duration_beats = 0.2},
		{freq = 150.0, duration_beats = 0.3},
	]
	return ToneGenerator.generate_melody(notes, 200.0, ToneGenerator.WaveType.SQUARE, 0.25, false)

# ── Evolution SFX ───────────────────────────────────────────────────────────

static func _evolve_sparkle() -> AudioStreamWAV:
	# High sparkle tones
	var notes := [
		{freq = 1200.0, duration_beats = 0.1},
		{freq = 1500.0, duration_beats = 0.1},
		{freq = 1800.0, duration_beats = 0.15},
	]
	return ToneGenerator.generate_melody(notes, 300.0, ToneGenerator.WaveType.SINE, 0.25, false)

static func _evolve_complete() -> AudioStreamWAV:
	# Completed fanfare
	var notes := [
		{freq = 523.0, duration_beats = 0.3},
		{freq = 659.0, duration_beats = 0.3},
		{freq = 784.0, duration_beats = 0.3},
		{freq = 1047.0, duration_beats = 0.8},
		{freq = 784.0, duration_beats = 0.2},
		{freq = 1047.0, duration_beats = 1.0},
	]
	return ToneGenerator.generate_melody(notes, 160.0, ToneGenerator.WaveType.TRIANGLE, 0.35, false)

# ── Level/Badge SFX ─────────────────────────────────────────────────────────

static func _level_up() -> AudioStreamWAV:
	var notes := [
		{freq = 440.0, duration_beats = 0.15},
		{freq = 554.0, duration_beats = 0.15},
		{freq = 659.0, duration_beats = 0.15},
		{freq = 880.0, duration_beats = 0.4},
	]
	return ToneGenerator.generate_melody(notes, 250.0, ToneGenerator.WaveType.TRIANGLE, 0.35, false)

static func _badge_earn() -> AudioStreamWAV:
	var notes := [
		{freq = 392.0, duration_beats = 0.25},
		{freq = 494.0, duration_beats = 0.25},
		{freq = 587.0, duration_beats = 0.25},
		{freq = 784.0, duration_beats = 0.5},
		{freq = 587.0, duration_beats = 0.15},
		{freq = 784.0, duration_beats = 0.15},
		{freq = 988.0, duration_beats = 0.8},
	]
	return ToneGenerator.generate_melody(notes, 180.0, ToneGenerator.WaveType.TRIANGLE, 0.4, false)

# ── Trade SFX ──────────────────────────────────────────────────────────────

static func _trade_offer() -> AudioStreamWAV:
	# Curious ascending ping
	var notes := [
		{freq = 500.0, duration_beats = 0.15},
		{freq = 700.0, duration_beats = 0.15},
		{freq = 900.0, duration_beats = 0.2},
	]
	return ToneGenerator.generate_melody(notes, 280.0, ToneGenerator.WaveType.SINE, 0.3, false)

static func _trade_complete() -> AudioStreamWAV:
	# Successful exchange jingle
	var notes := [
		{freq = 523.0, duration_beats = 0.2},
		{freq = 659.0, duration_beats = 0.2},
		{freq = 784.0, duration_beats = 0.2},
		{freq = 1047.0, duration_beats = 0.3},
		{freq = 784.0, duration_beats = 0.15},
		{freq = 1047.0, duration_beats = 0.5},
	]
	return ToneGenerator.generate_melody(notes, 200.0, ToneGenerator.WaveType.TRIANGLE, 0.35, false)

# ── PvP SFX ────────────────────────────────────────────────────────────────

static func _pvp_win() -> AudioStreamWAV:
	# Triumphant fanfare
	var notes := [
		{freq = 523.0, duration_beats = 0.2},
		{freq = 659.0, duration_beats = 0.2},
		{freq = 784.0, duration_beats = 0.2},
		{freq = 1047.0, duration_beats = 0.5},
		{freq = 880.0, duration_beats = 0.15},
		{freq = 1047.0, duration_beats = 0.15},
		{freq = 1319.0, duration_beats = 0.8},
	]
	return ToneGenerator.generate_melody(notes, 180.0, ToneGenerator.WaveType.TRIANGLE, 0.4, false)

static func _pvp_lose() -> AudioStreamWAV:
	# Somber descending tones
	var notes := [
		{freq = 500.0, duration_beats = 0.3},
		{freq = 400.0, duration_beats = 0.3},
		{freq = 330.0, duration_beats = 0.3},
		{freq = 260.0, duration_beats = 0.6},
	]
	return ToneGenerator.generate_melody(notes, 140.0, ToneGenerator.WaveType.TRIANGLE, 0.3, false)
