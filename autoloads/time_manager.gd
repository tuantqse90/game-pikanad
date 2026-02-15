extends Node

## Day/night cycle based on real system time. Provides tint colors
## and phase signals for CanvasModulate in zones and overworld.

enum TimePhase { MORNING, AFTERNOON, EVENING, NIGHT }

signal phase_changed(new_phase: TimePhase)

var current_phase: TimePhase = TimePhase.AFTERNOON

const PHASE_COLORS := {
	TimePhase.MORNING:   Color(1.0, 0.95, 0.9),     # Warm white
	TimePhase.AFTERNOON: Color(1.0, 1.0, 1.0),       # Neutral
	TimePhase.EVENING:   Color(0.9, 0.7, 0.5),       # Orange tint
	TimePhase.NIGHT:     Color(0.4, 0.4, 0.7),       # Blue-dark tint
}

func _ready() -> void:
	_update_phase()

func _process(_delta: float) -> void:
	# Check phase every frame (cheap operation)
	var old_phase := current_phase
	_update_phase()
	if current_phase != old_phase:
		phase_changed.emit(current_phase)

func _update_phase() -> void:
	var dt := Time.get_datetime_dict_from_system()
	var hour: int = dt.get("hour", 12)
	if hour >= 6 and hour < 12:
		current_phase = TimePhase.MORNING
	elif hour >= 12 and hour < 18:
		current_phase = TimePhase.AFTERNOON
	elif hour >= 18 and hour < 22:
		current_phase = TimePhase.EVENING
	else:
		current_phase = TimePhase.NIGHT

func get_tint_color() -> Color:
	return PHASE_COLORS[current_phase]

func get_phase_name() -> String:
	match current_phase:
		TimePhase.MORNING:   return "Morning"
		TimePhase.AFTERNOON: return "Afternoon"
		TimePhase.EVENING:   return "Evening"
		TimePhase.NIGHT:     return "Night"
	return "Day"
