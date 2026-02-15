extends RefCounted
class_name ToneGenerator

## Procedural audio generation utility — sine, square, triangle, noise waveforms
## with ADSR envelope and melody sequencing.

enum WaveType { SINE, SQUARE, TRIANGLE, NOISE }

const SAMPLE_RATE := 22050
const MIX_RATE := 22050

# ADSR envelope defaults
const DEFAULT_ATTACK := 0.02
const DEFAULT_DECAY := 0.05
const DEFAULT_SUSTAIN := 0.7
const DEFAULT_RELEASE := 0.05

static func generate_tone(freq: float, duration: float, wave_type: int = WaveType.SINE,
		volume: float = 0.5, attack: float = DEFAULT_ATTACK, decay: float = DEFAULT_DECAY,
		sustain_level: float = DEFAULT_SUSTAIN, release: float = DEFAULT_RELEASE) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit samples

	for i in num_samples:
		var t := float(i) / float(SAMPLE_RATE)
		var sample := _wave_sample(freq, t, wave_type)
		var envelope := _adsr_envelope(t, duration, attack, decay, sustain_level, release)
		var value := int(sample * envelope * volume * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = data
	return stream

static func generate_melody(notes: Array, bpm: float = 120.0, wave_type: int = WaveType.SQUARE,
		volume: float = 0.4, loop: bool = true) -> AudioStreamWAV:
	var beat_duration := 60.0 / bpm
	var all_data := PackedByteArray()

	for note in notes:
		var freq: float = note.get("freq", 440.0)
		var beats: float = note.get("duration_beats", 1.0)
		var wave: int = note.get("wave", wave_type)
		var note_vol: float = note.get("volume", volume)
		var duration := beats * beat_duration
		var num_samples := int(SAMPLE_RATE * duration)

		for i in num_samples:
			var t := float(i) / float(SAMPLE_RATE)
			var sample: float
			if freq <= 0.0:
				sample = 0.0  # Rest note
			else:
				sample = _wave_sample(freq, t, wave)
				var envelope := _adsr_envelope(t, duration, DEFAULT_ATTACK, DEFAULT_DECAY, DEFAULT_SUSTAIN, DEFAULT_RELEASE)
				sample *= envelope
			var value := int(sample * note_vol * 32767.0)
			value = clampi(value, -32768, 32767)
			all_data.append(value & 0xFF)
			all_data.append((value >> 8) & 0xFF)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = all_data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = all_data.size() / 2
	return stream

static func _wave_sample(freq: float, t: float, wave_type: int) -> float:
	match wave_type:
		WaveType.SINE:
			return sin(TAU * freq * t)
		WaveType.SQUARE:
			return 1.0 if fmod(freq * t, 1.0) < 0.5 else -1.0
		WaveType.TRIANGLE:
			var phase := fmod(freq * t, 1.0)
			return 4.0 * abs(phase - 0.5) - 1.0
		WaveType.NOISE:
			return randf_range(-1.0, 1.0)
	return 0.0

static func _adsr_envelope(t: float, duration: float, attack: float, decay: float,
		sustain_level: float, release: float) -> float:
	var release_start := duration - release
	if t < attack:
		return t / attack if attack > 0.0 else 1.0
	elif t < attack + decay:
		var decay_progress := (t - attack) / decay if decay > 0.0 else 1.0
		return 1.0 - (1.0 - sustain_level) * decay_progress
	elif t < release_start:
		return sustain_level
	else:
		var release_progress := (t - release_start) / release if release > 0.0 else 1.0
		return sustain_level * (1.0 - release_progress)
