extends Area2D

## Portal that transports the player to another zone.
## Features gold archway visual with pulsing glow effect.

@export var target_zone_path: String = ""
@export var spawn_offset := Vector2(0, 40)
@export var portal_label: String = "???"

# Zone name -> required badge message mapping
const GATED_ZONES := {
	"sky_peaks": {"zone": "Sky Peaks", "badge": 5, "name": "Rumble"},
	"lava_core": {"zone": "Lava Core", "badge": 6, "name": "Tempest"},
	"champion_arena": {"zone": "Champion Arena", "badge_count": 7},
}

var _label: Label
var _archway_group: Node2D
var _glow_time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Gold archway visual
	_build_archway()

	# Portal label
	_label = Label.new()
	_label.text = portal_label
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40, -38)
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	add_child(_label)

func _build_archway() -> void:
	_archway_group = Node2D.new()
	add_child(_archway_group)

	var gold := Color(0.85, 0.7, 0.2, 0.8)
	var gold_dark := Color(0.6, 0.45, 0.1, 0.6)

	# Left pillar
	var left := ColorRect.new()
	left.color = gold
	left.size = Vector2(6, 28)
	left.position = Vector2(-18, -20)
	_archway_group.add_child(left)

	# Right pillar
	var right := ColorRect.new()
	right.color = gold
	right.size = Vector2(6, 28)
	right.position = Vector2(12, -20)
	_archway_group.add_child(right)

	# Top bar
	var top := ColorRect.new()
	top.color = gold
	top.size = Vector2(36, 6)
	top.position = Vector2(-18, -24)
	_archway_group.add_child(top)

	# Shadow base
	var base := ColorRect.new()
	base.color = gold_dark
	base.size = Vector2(36, 3)
	base.position = Vector2(-18, 8)
	_archway_group.add_child(base)

func _process(delta: float) -> void:
	# Pulsing glow (alpha oscillation 0.6-1.0)
	_glow_time += delta * 2.0
	var alpha := 0.6 + sin(_glow_time) * 0.2
	if _archway_group:
		_archway_group.modulate.a = alpha

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and target_zone_path != "":
		# Tutorial: first portal
		if TutorialManager and not TutorialManager.is_completed("first_portal"):
			TutorialManager.show_tutorial("first_portal")
			return
		if not _check_access():
			return
		AudioManager.play_sound(AudioManager.SFX.PORTAL_ENTER)
		GameManager.set_meta("zone_spawn_offset", spawn_offset)
		SceneManager.go_to_zone(target_zone_path)

func _check_access() -> bool:
	if not BadgeManager:
		return true

	var zone_key := target_zone_path.get_file().get_basename()

	if not GATED_ZONES.has(zone_key):
		return true

	var gate: Dictionary = GATED_ZONES[zone_key]

	if gate.has("badge_count"):
		var required: int = gate["badge_count"]
		if BadgeManager.badge_count() < required:
			_show_gate_message("You need all %d badges to enter the Champion Arena!" % required)
			return false
	elif gate.has("badge"):
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
