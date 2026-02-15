extends Area2D

## Portal that transports the player to another zone.

@export var target_zone_path: String = ""
@export var spawn_offset := Vector2(0, 40)  # Where to place player in new zone
@export var portal_label: String = "???"

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
		GameManager.set_meta("zone_spawn_offset", spawn_offset)
		SceneManager.go_to_zone(target_zone_path)
