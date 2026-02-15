extends Area2D

## Portal that transports the player to another zone.
## Checks badge requirements for gated zones.

@export var target_zone_path: String = ""
@export var spawn_offset := Vector2(0, 40)  # Where to place player in new zone
@export var portal_label: String = "???"

# Zone name -> required badge message mapping
const GATED_ZONES := {
	"sky_peaks": {"zone": "Sky Peaks", "badge": 5, "name": "Rumble"},
	"lava_core": {"zone": "Lava Core", "badge": 6, "name": "Tempest"},
	"champion_arena": {"zone": "Champion Arena", "badge_count": 7},
}

var _label: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Visual indicator
	_label = Label.new()
	_label.text = portal_label
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-30, -24)
	add_child(_label)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and target_zone_path != "":
		# Check zone access gating
		if not _check_access():
			return
		AudioManager.play_sound(AudioManager.SFX.PORTAL_ENTER)
		GameManager.set_meta("zone_spawn_offset", spawn_offset)
		SceneManager.go_to_zone(target_zone_path)

func _check_access() -> bool:
	if not BadgeManager:
		return true

	# Extract zone key from path (e.g., "sky_peaks" from ".../sky_peaks.tscn")
	var zone_key := target_zone_path.get_file().get_basename()

	if not GATED_ZONES.has(zone_key):
		return true

	var gate: Dictionary = GATED_ZONES[zone_key]

	if gate.has("badge_count"):
		# Needs N badges total
		var required: int = gate["badge_count"]
		if BadgeManager.badge_count() < required:
			_show_gate_message("You need all %d badges to enter the Champion Arena!" % required)
			return false
	elif gate.has("badge"):
		# Needs a specific badge
		var badge_num: int = gate["badge"]
		if not BadgeManager.has_badge(badge_num):
			var badge_name: String = BadgeManager.BADGE_NAMES[badge_num - 1]
			_show_gate_message("You need the %s Badge to enter %s!" % [badge_name, gate["zone"]])
			return false

	return true

func _show_gate_message(text: String) -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		dialogue_box.show_dialogue([text], func():
			GameManager.change_state(GameManager.GameState.OVERWORLD)
		)
