extends CanvasLayer

## Evolution screen overlay — shows old sprite → new sprite with confirm/cancel.

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
	info_label.text = "%s is evolving into %s!" % [old_name, new_name]

	# Set sprites
	if creature.data.sprite_texture:
		old_sprite.texture = creature.data.sprite_texture
	if new_data and new_data.sprite_texture:
		new_sprite.texture = new_data.sprite_texture

	evolve_btn.grab_focus()

func _on_evolve() -> void:
	if _creature:
		_creature.evolve()
	visible = false
	evolution_confirmed.emit()

func _on_stop() -> void:
	visible = false
	evolution_cancelled.emit()
