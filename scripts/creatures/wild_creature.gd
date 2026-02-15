extends Area2D

## A wild creature visible on the overworld map.
## Wanders randomly and triggers battle on contact with player.

@export var creature_data: CreatureData
@export var level_min: int = 2
@export var level_max: int = 6

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

const WANDER_SPEED := 40.0
const WANDER_TIME_MIN := 1.0
const WANDER_TIME_MAX := 3.0
const IDLE_TIME_MIN := 1.5
const IDLE_TIME_MAX := 4.0

var _direction := Vector2.ZERO
var _wander_timer := 0.0
var _is_wandering := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_idle()
	_setup_sprite()

func _setup_sprite() -> void:
	if not creature_data or not anim_sprite:
		return
	# Use overworld_texture if available, fallback to sprite_texture
	if creature_data.overworld_texture:
		_build_sprite_frames(creature_data.overworld_texture, 32)
	elif creature_data.sprite_texture:
		# Fallback: single static frame
		var frames := SpriteFrames.new()
		frames.add_animation("idle")
		frames.add_frame("idle", creature_data.sprite_texture)
		anim_sprite.sprite_frames = frames
		anim_sprite.play("idle")

func _build_sprite_frames(sheet: Texture2D, frame_size: int) -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 3.0)
	frames.set_animation_loop("idle", true)
	var frame_count := sheet.get_width() / frame_size
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_size, 0, frame_size, frame_size)
		frames.add_frame("idle", atlas)
	# Remove default animation if it exists
	if frames.has_animation("default"):
		frames.remove_animation("default")
	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.OVERWORLD:
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		if _is_wandering:
			_start_idle()
		else:
			_start_wander()

	if _is_wandering:
		position += _direction * WANDER_SPEED * delta
		# Flip sprite based on direction
		if anim_sprite and _direction.x != 0:
			anim_sprite.flip_h = _direction.x < 0

func _start_wander() -> void:
	_is_wandering = true
	_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_wander_timer = randf_range(WANDER_TIME_MIN, WANDER_TIME_MAX)

func _start_idle() -> void:
	_is_wandering = false
	_direction = Vector2.ZERO
	_wander_timer = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and creature_data:
		var wild_level := randi_range(level_min, level_max)
		SceneManager.go_to_battle.call_deferred(creature_data, wild_level)
