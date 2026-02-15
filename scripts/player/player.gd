extends CharacterBody2D

const SPEED := 120.0
const RUN_SPEED := 180.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "down"

func _physics_process(_delta: float) -> void:
	if GameManager.state != GameManager.GameState.OVERWORLD:
		velocity = Vector2.ZERO
		return

	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")

	if input != Vector2.ZERO:
		input = input.normalized()
		var current_speed := RUN_SPEED if Input.is_action_pressed("run") else SPEED
		velocity = input * current_speed
		# Determine facing direction
		if abs(input.x) > abs(input.y):
			facing = "right" if input.x > 0 else "left"
		else:
			facing = "down" if input.y > 0 else "up"
		_play_anim("walk_" + facing)
	else:
		velocity = Vector2.ZERO
		_play_anim("idle_" + facing)

	move_and_slide()

func _play_anim(anim_name: String) -> void:
	if not anim_sprite:
		return
	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		if anim_sprite.animation != anim_name:
			anim_sprite.play(anim_name)
	elif not anim_sprite.is_playing():
		anim_sprite.play()
