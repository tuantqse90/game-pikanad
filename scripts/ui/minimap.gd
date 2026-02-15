extends Control

## Small minimap overlay in top-right corner of overworld.
## Shows player position, portals, and NPCs as colored dots.

const MINIMAP_W := 80.0
const MINIMAP_H := 60.0
const WORLD_HALF_W := 320.0
const WORLD_HALF_H := 240.0
const BG_COLOR := Color(0.1, 0.1, 0.15, 0.6)
const PLAYER_COLOR := Color.WHITE
const PORTAL_COLOR := Color(1.0, 0.9, 0.2)
const NPC_COLOR := Color(0.3, 0.6, 1.0)

var _parent_scene: Node2D

func setup(scene: Node2D) -> void:
	_parent_scene = scene
	# Position in top-right corner
	position = Vector2(548, 8)
	custom_minimum_size = Vector2(MINIMAP_W, MINIMAP_H)
	size = Vector2(MINIMAP_W, MINIMAP_H)
	z_index = 50
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(MINIMAP_W, MINIMAP_H)), BG_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(MINIMAP_W, MINIMAP_H)), Color(0.3, 0.3, 0.4, 0.5), false, 1.0)

	if not _parent_scene:
		return

	# Draw portals
	for child in _parent_scene.get_children():
		if child is Area2D and child.has_method("_check_access"):
			_draw_dot(_world_to_minimap(child.position), PORTAL_COLOR, 2.0)
		elif child is Area2D and child.has_method("interact"):
			_draw_dot(_world_to_minimap(child.position), NPC_COLOR, 2.0)

	# Draw player
	var player := _parent_scene.get_node_or_null("Player")
	if player:
		_draw_dot(_world_to_minimap(player.position), PLAYER_COLOR, 3.0)

func _world_to_minimap(world_pos: Vector2) -> Vector2:
	var x := ((world_pos.x + WORLD_HALF_W) / (WORLD_HALF_W * 2.0)) * MINIMAP_W
	var y := ((world_pos.y + WORLD_HALF_H) / (WORLD_HALF_H * 2.0)) * MINIMAP_H
	return Vector2(clampf(x, 1, MINIMAP_W - 1), clampf(y, 1, MINIMAP_H - 1))

func _draw_dot(pos: Vector2, color: Color, radius: float) -> void:
	draw_circle(pos, radius, color)
