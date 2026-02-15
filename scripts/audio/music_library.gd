extends RefCounted
class_name MusicLibrary

## Pre-defined procedural melodies for each MusicTrack.
## Uses ToneGenerator to create AudioStreamWAV tracks.

# Note frequency constants (octave 4 & 5)
const C4 := 261.63; const D4 := 293.66; const E4 := 329.63; const F4 := 349.23
const G4 := 392.00; const A4 := 440.00; const B4 := 493.88
const C5 := 523.25; const D5 := 587.33; const E5 := 659.25; const F5 := 698.46
const G5 := 783.99; const A5 := 880.00
const C3 := 130.81; const E3 := 164.81; const G3 := 196.00; const A3 := 220.00
const B3 := 246.94; const D3 := 146.83; const F3 := 174.61
const REST := 0.0

# Cache generated tracks
static var _cache: Dictionary = {}

static func get_track(track_id: int) -> AudioStreamWAV:
	if _cache.has(track_id):
		return _cache[track_id]
	var stream: AudioStreamWAV = _generate_track(track_id)
	_cache[track_id] = stream
	return stream

static func _generate_track(track_id: int) -> AudioStreamWAV:
	match track_id:
		0:  # MENU
			return _menu_theme()
		1:  # OVERWORLD
			return _overworld_theme()
		2:  # BATTLE
			return _battle_theme()
		3:  # TRAINER_BATTLE
			return _trainer_battle_theme()
		4:  # VICTORY
			return _victory_theme()
		5:  # EVOLUTION
			return _evolution_theme()
		6:  # SHOP
			return _shop_theme()
		7:  # CHAMPION
			return _champion_theme()
	return _menu_theme()

static func _menu_theme() -> AudioStreamWAV:
	# Gentle arpeggiated chords (C-E-G pattern) — calm and inviting
	var notes := [
		{freq = C4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = G4, duration_beats = 0.5}, {freq = C5, duration_beats = 0.5},
		{freq = G4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = C4, duration_beats = 0.5}, {freq = REST, duration_beats = 0.5},
		{freq = A3, duration_beats = 0.5}, {freq = C4, duration_beats = 0.5},
		{freq = E4, duration_beats = 0.5}, {freq = A4, duration_beats = 0.5},
		{freq = E4, duration_beats = 0.5}, {freq = C4, duration_beats = 0.5},
		{freq = A3, duration_beats = 0.5}, {freq = REST, duration_beats = 0.5},
		{freq = F3, duration_beats = 0.5}, {freq = A3, duration_beats = 0.5},
		{freq = C4, duration_beats = 0.5}, {freq = F4, duration_beats = 0.5},
		{freq = C4, duration_beats = 0.5}, {freq = A3, duration_beats = 0.5},
		{freq = G3, duration_beats = 0.5}, {freq = B3, duration_beats = 0.5},
		{freq = D4, duration_beats = 0.5}, {freq = G4, duration_beats = 0.5},
		{freq = D4, duration_beats = 0.5}, {freq = B3, duration_beats = 0.5},
		{freq = G3, duration_beats = 0.5}, {freq = REST, duration_beats = 0.5},
		{freq = REST, duration_beats = 0.5}, {freq = REST, duration_beats = 0.5},
	]
	return ToneGenerator.generate_melody(notes, 100.0, ToneGenerator.WaveType.TRIANGLE, 0.25)

static func _overworld_theme() -> AudioStreamWAV:
	# Upbeat walking melody — major key, bouncy rhythm
	var notes := [
		{freq = C4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = G4, duration_beats = 1.0}, {freq = A4, duration_beats = 0.5},
		{freq = G4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = D4, duration_beats = 0.5},
		{freq = C4, duration_beats = 0.5}, {freq = D4, duration_beats = 0.5},
		{freq = E4, duration_beats = 1.0}, {freq = C4, duration_beats = 1.0},
		{freq = REST, duration_beats = 0.5},
		{freq = D4, duration_beats = 0.5}, {freq = F4, duration_beats = 0.5},
		{freq = A4, duration_beats = 1.0}, {freq = G4, duration_beats = 0.5},
		{freq = F4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = D4, duration_beats = 0.5},
		{freq = E4, duration_beats = 0.5}, {freq = G4, duration_beats = 0.5},
		{freq = C5, duration_beats = 1.0}, {freq = G4, duration_beats = 1.0},
		{freq = REST, duration_beats = 0.5}, {freq = REST, duration_beats = 0.5},
	]
	return ToneGenerator.generate_melody(notes, 130.0, ToneGenerator.WaveType.SQUARE, 0.2)

static func _battle_theme() -> AudioStreamWAV:
	# Fast-paced tension — minor key, quick tempo
	var notes := [
		{freq = A3, duration_beats = 0.25}, {freq = A3, duration_beats = 0.25},
		{freq = C4, duration_beats = 0.25}, {freq = A3, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.5}, {freq = D4, duration_beats = 0.5},
		{freq = C4, duration_beats = 0.5}, {freq = B3, duration_beats = 0.5},
		{freq = A3, duration_beats = 0.25}, {freq = A3, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.25}, {freq = A3, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.5}, {freq = F4, duration_beats = 0.5},
		{freq = E4, duration_beats = 0.5}, {freq = D4, duration_beats = 0.5},
		{freq = C4, duration_beats = 0.25}, {freq = C4, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.25}, {freq = G4, duration_beats = 0.25},
		{freq = A4, duration_beats = 0.5}, {freq = G4, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.25},
		{freq = D4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = A3, duration_beats = 1.0},
	]
	return ToneGenerator.generate_melody(notes, 160.0, ToneGenerator.WaveType.SQUARE, 0.25)

static func _trainer_battle_theme() -> AudioStreamWAV:
	# More intense battle — faster, accented
	var notes := [
		{freq = A3, duration_beats = 0.25}, {freq = C4, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.25}, {freq = A4, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.25}, {freq = E4, duration_beats = 0.25},
		{freq = C4, duration_beats = 0.25}, {freq = E4, duration_beats = 0.25},
		{freq = F4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.25},
		{freq = D4, duration_beats = 0.25},
		{freq = C4, duration_beats = 0.25}, {freq = D4, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.5},
		{freq = A4, duration_beats = 0.25}, {freq = G4, duration_beats = 0.25},
		{freq = A4, duration_beats = 0.25}, {freq = B4, duration_beats = 0.25},
		{freq = C5, duration_beats = 0.5}, {freq = A4, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.5}, {freq = F4, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.25},
		{freq = D4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = A3, duration_beats = 0.5}, {freq = REST, duration_beats = 0.25},
		{freq = A3, duration_beats = 0.25},
	]
	return ToneGenerator.generate_melody(notes, 180.0, ToneGenerator.WaveType.SQUARE, 0.3)

static func _victory_theme() -> AudioStreamWAV:
	# Short triumphant fanfare — ascending major, 4 bars, no loop
	var notes := [
		{freq = C4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = G4, duration_beats = 0.5}, {freq = C5, duration_beats = 1.5},
		{freq = B4, duration_beats = 0.5}, {freq = C5, duration_beats = 0.5},
		{freq = D5, duration_beats = 0.5}, {freq = E5, duration_beats = 1.5},
		{freq = C5, duration_beats = 0.5}, {freq = E5, duration_beats = 0.5},
		{freq = G5, duration_beats = 1.0}, {freq = REST, duration_beats = 0.5},
		{freq = C5, duration_beats = 0.5}, {freq = G5, duration_beats = 2.0},
	]
	return ToneGenerator.generate_melody(notes, 140.0, ToneGenerator.WaveType.TRIANGLE, 0.35, false)

static func _evolution_theme() -> AudioStreamWAV:
	# Ascending scale with sparkle tones — building excitement
	var notes := [
		{freq = C4, duration_beats = 0.5}, {freq = D4, duration_beats = 0.5},
		{freq = E4, duration_beats = 0.5}, {freq = F4, duration_beats = 0.5},
		{freq = G4, duration_beats = 0.5}, {freq = A4, duration_beats = 0.5},
		{freq = B4, duration_beats = 0.5}, {freq = C5, duration_beats = 1.0},
		{freq = E5, duration_beats = 0.25, wave = ToneGenerator.WaveType.SINE},
		{freq = G5, duration_beats = 0.25, wave = ToneGenerator.WaveType.SINE},
		{freq = C5, duration_beats = 0.25, wave = ToneGenerator.WaveType.SINE},
		{freq = E5, duration_beats = 0.25, wave = ToneGenerator.WaveType.SINE},
		{freq = G5, duration_beats = 0.5, wave = ToneGenerator.WaveType.SINE},
		{freq = C5, duration_beats = 1.5},
	]
	return ToneGenerator.generate_melody(notes, 120.0, ToneGenerator.WaveType.TRIANGLE, 0.3, false)

static func _shop_theme() -> AudioStreamWAV:
	# Relaxed jazzy loop — swung feel, warm tones
	var notes := [
		{freq = C4, duration_beats = 0.75}, {freq = E4, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.75}, {freq = A4, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = D4, duration_beats = 0.75}, {freq = F4, duration_beats = 0.25},
		{freq = A4, duration_beats = 0.75}, {freq = G4, duration_beats = 0.25},
		{freq = F4, duration_beats = 0.5}, {freq = D4, duration_beats = 0.5},
		{freq = E4, duration_beats = 0.75}, {freq = G4, duration_beats = 0.25},
		{freq = C5, duration_beats = 0.75}, {freq = B4, duration_beats = 0.25},
		{freq = A4, duration_beats = 0.5}, {freq = G4, duration_beats = 0.5},
		{freq = F4, duration_beats = 0.5}, {freq = E4, duration_beats = 0.5},
		{freq = D4, duration_beats = 0.5}, {freq = C4, duration_beats = 0.5},
		{freq = REST, duration_beats = 1.0},
	]
	return ToneGenerator.generate_melody(notes, 90.0, ToneGenerator.WaveType.TRIANGLE, 0.2)

static func _champion_theme() -> AudioStreamWAV:
	# Dramatic boss theme — driving rhythm, intensity
	var notes := [
		{freq = A3, duration_beats = 0.25}, {freq = A3, duration_beats = 0.25},
		{freq = A3, duration_beats = 0.25}, {freq = REST, duration_beats = 0.25},
		{freq = C4, duration_beats = 0.25}, {freq = E4, duration_beats = 0.25},
		{freq = A4, duration_beats = 0.5},
		{freq = G4, duration_beats = 0.25}, {freq = A4, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.25}, {freq = E4, duration_beats = 0.25},
		{freq = C4, duration_beats = 0.5}, {freq = D4, duration_beats = 0.5},
		{freq = E4, duration_beats = 0.25}, {freq = E4, duration_beats = 0.25},
		{freq = E4, duration_beats = 0.25}, {freq = REST, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.25}, {freq = A4, duration_beats = 0.25},
		{freq = C5, duration_beats = 0.5},
		{freq = B4, duration_beats = 0.25}, {freq = A4, duration_beats = 0.25},
		{freq = G4, duration_beats = 0.25}, {freq = E4, duration_beats = 0.25},
		{freq = A4, duration_beats = 0.5}, {freq = REST, duration_beats = 0.25},
		{freq = A3, duration_beats = 0.25},
	]
	return ToneGenerator.generate_melody(notes, 170.0, ToneGenerator.WaveType.SQUARE, 0.3)
