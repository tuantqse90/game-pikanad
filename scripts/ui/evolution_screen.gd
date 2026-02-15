extends CanvasLayer

## Evolution screen — particle burst behind sprites, stat comparison text.

signal evolution_confirmed
signal evolution_cancelled

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Overlay/CenterContainer/Panel
@onready var title_label: Label = $Overlay/CenterContainer/Panel/VBox/TitleLabel
@onready var sprites_container: HBoxContainer = $Overlay/CenterContainer/Panel/VBox/SpritesContainer
@onready var old_sprite: TextureRect = $Overlay/CenterContainer/Panel/VBox/SpritesContainer/OldSprite
@onready var arrow_label: Label = $Overlay/CenterContainer/Panel/VBox/SpritesContainer/ArrowLabel
@onready var new_sprite: TextureRect = $Overlay/CenterContainer/Panel/VBox/SpritesContainer/NewSprite
@onready var info_label: Label = $Overlay/CenterContainer/Panel/VBox/InfoLabel
@onready var evolve_btn: Button = $Overlay/CenterContainer/Panel/VBox/ButtonRow/EvolveBtn
@onready var stop_btn: Button = $Overlay/CenterContainer/Panel/VBox/ButtonRow/StopBtn

var _creature: CreatureInstance
var _particles: CPUParticles2D

func _ready() -> void:
	visible = false
	evolve_btn.pressed.connect(_on_evolve)
	stop_btn.pressed.connect(_on_stop)

func show_evolution(creature: CreatureInstance) -> void:
	_creature = creature
	visible = true

	var old_name := creature.data.species_name
	var new_data := creature.data.evolves_into
	var new_name := new_data.species_name if new_data else "???"

	title_label.text = "Evolution!"
	title_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	title_label.add_theme_font_size_override("font_size", 16)

	# Stat comparison text
	if new_data:
		info_label.text = "%s -> %s\nHP: %d -> %d  ATK: %d -> %d  DEF: %d -> %d  SPD: %d -> %d" % [
			old_name, new_name,
			creature.data.base_hp, new_data.base_hp,
			creature.data.base_attack, new_data.base_attack,
			creature.data.base_defense, new_data.base_defense,
			creature.data.base_speed, new_data.base_speed,
		]
	else:
		info_label.text = "%s is evolving into %s!" % [old_name, new_name]

	# Set sprites
	if creature.data.sprite_texture:
		old_sprite.texture = creature.data.sprite_texture
	if new_data and new_data.sprite_texture:
		new_sprite.texture = new_data.sprite_texture

	# Arrow styling
	arrow_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)

	# Particle burst behind sprites
	_create_evolution_particles()

	evolve_btn.grab_focus()

func _create_evolution_particles() -> void:
	_particles = CPUParticles2D.new()
	_particles.emitting = true
	_particles.amount = 20
	_particles.lifetime = 2.0
	_particles.one_shot = false
	_particles.direction = Vector2(0, -1)
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, 0)
	_particles.initial_velocity_min = 15.0
	_particles.initial_velocity_max = 35.0
	_particles.scale_amount_min = 0.5
	_particles.scale_amount_max = 2.0
	_particles.color = Color(1.0, 0.9, 0.3, 0.5)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(60, 30)
	_particles.position = Vector2(0, 0)
	# Wrap in a Node2D for sprites_container
	var holder := Node2D.new()
	sprites_container.add_child(holder)
	holder.add_child(_particles)

func _on_evolve() -> void:
	if _creature:
		_creature.evolve()
	_cleanup_particles()
	visible = false
	evolution_confirmed.emit()

func _on_stop() -> void:
	_cleanup_particles()
	visible = false
	evolution_cancelled.emit()

func _cleanup_particles() -> void:
	if _particles:
		_particles.emitting = false
