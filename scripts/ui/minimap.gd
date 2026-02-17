extends Control

## Small minimap overlay in top-right corner of overworld.
## Shows player position, portals, and NPCs as colored dots.
## Features double-border matching theme and zone name label.

const MINIMAP_W := 100.0
const MINIMAP_H := 75.0
const WORLD_HALF_W := 320.0
const WORLD_HALF_H := 240.0
const BG_COLOR := Color(0.06, 0.05, 0.1, 0.7)
const BORDER_OUTER := Color(0.45, 0.42, 0.58, 0.8)
const BORDER_INNER := Color(0.08, 0.06, 0.14, 0.8)
const PLAYER_COLOR := Color.WHITE
const PORTAL_COLOR := Color(1.0, 0.9, 0.2)
const NPC_COLOR := Color(0.3, 0.6, 1.0)

var _parent_scene: Node2D
var _zone_name := ""
var _pulse_time := 0.0

func setup(scene: Node2D, p_zone_name: String = "") -> void:
	_parent_scene = scene
	_zone_name = p_zone_name
	# Position in top-right corner
	position = Vector2(528, 8)
	custom_minimum_size = Vector2(MINIMAP_W, MINIMAP_H)
	size = Vector2(MINIMAP_W, MINIMAP_H)
	z_index = 50
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_pulse_time += delta * 3.0
	queue_redraw()

func _draw() -> void:
	# Outer glow border (soft wider line)
	draw_rect(Rect2(Vector2(-2, -2), Vector2(MINIMAP_W + 4, MINIMAP_H + 4)), Color(0.35, 0.6, 0.95, 0.15), false, 3.0)
	# Double border: outer highlight + inner shadow + bg
	draw_rect(Rect2(Vector2(-1, -1), Vector2(MINIMAP_W + 2, MINIMAP_H + 2)), BORDER_OUTER, false, 2.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(MINIMAP_W, MINIMAP_H)), BG_COLOR)
	draw_rect(Rect2(Vector2(1, 1), Vector2(MINIMAP_W - 2, MINIMAP_H - 2)), BORDER_INNER, false, 1.0)
	# Top highlight line (inner glow)
	draw_line(Vector2(2, 2), Vector2(MINIMAP_W - 2, 2), Color(0.6, 0.58, 0.75, 0.3), 1.0)

	# Zone name label at top
	if _zone_name != "":
		draw_string(ThemeDB.fallback_font, Vector2(4, 10), _zone_name, HORIZONTAL_ALIGNMENT_LEFT, MINIMAP_W - 8, 7, Color(0.7, 0.68, 0.8, 0.8))

	if not _parent_scene:
		return

	# Draw portals with pulse
	var portal_pulse := 2.0 + sin(_pulse_time) * 1.0
	for child in _parent_scene.get_children():
		if child is Area2D and child.has_method("_check_access"):
			_draw_dot(_world_to_minimap(child.position), PORTAL_COLOR, portal_pulse)
		elif child is Area2D and child.has_method("interact"):
			_draw_dot(_world_to_minimap(child.position), NPC_COLOR, 2.0)

	# Draw player
	var player := _parent_scene.get_node_or_null("Player")
	if player:
		_draw_dot(_world_to_minimap(player.position), PLAYER_COLOR, 3.0)

func _world_to_minimap(world_pos: Vector2) -> Vector2:
	var x := ((world_pos.x + WORLD_HALF_W) / (WORLD_HALF_W * 2.0)) * MINIMAP_W
	var y := ((world_pos.y + WORLD_HALF_H) / (WORLD_HALF_H * 2.0)) * MINIMAP_H
	return Vector2(clampf(x, 2, MINIMAP_W - 2), clampf(y, 14, MINIMAP_H - 2))

func _draw_dot(pos: Vector2, color: Color, radius: float) -> void:
	draw_circle(pos, radius, color)
