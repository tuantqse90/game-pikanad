extends CanvasLayer

## Skill replacement dialog — shows current 4 skills + new skill, player picks a slot.

signal skill_replaced(slot_index: int)
signal skill_cancelled

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Overlay/CenterContainer/Panel
@onready var title_label: Label = $Overlay/CenterContainer/Panel/VBox/TitleLabel
@onready var new_skill_label: Label = $Overlay/CenterContainer/Panel/VBox/NewSkillLabel
@onready var skill_list: VBoxContainer = $Overlay/CenterContainer/Panel/VBox/SkillList
@onready var cancel_btn: Button = $Overlay/CenterContainer/Panel/VBox/CancelBtn

var _creature: CreatureInstance
var _new_skill: SkillData

func _ready() -> void:
	visible = false
	cancel_btn.pressed.connect(_on_cancel)

func show_dialog(creature: CreatureInstance, new_skill: Resource) -> void:
	_creature = creature
	_new_skill = new_skill as SkillData
	visible = true

	title_label.text = "Replace a skill?"
	if _new_skill:
		new_skill_label.text = "New: %s (Pow:%d, %s)" % [_new_skill.skill_name, _new_skill.power, _get_category_name(_new_skill.category)]
	else:
		new_skill_label.text = "New skill"

	_build_skill_list()

func _build_skill_list() -> void:
	for child in skill_list.get_children():
		child.queue_free()

	for i in _creature.active_skills.size():
		var skill: SkillData = _creature.active_skills[i] as SkillData
		if not skill:
			continue
		var btn := Button.new()
		btn.text = "%d. %s (Pow:%d, %s)" % [i + 1, skill.skill_name, skill.power, _get_category_name(skill.category)]
		btn.custom_minimum_size = Vector2(0, 30)
		var idx := i
		btn.pressed.connect(func(): _on_replace(idx))
		skill_list.add_child(btn)

func _get_category_name(category: SkillData.Category) -> String:
	match category:
		SkillData.Category.ATTACK: return "ATK"
		SkillData.Category.STATUS: return "STS"
		SkillData.Category.HEAL: return "HEL"
		_: return "???"

func _on_replace(slot_index: int) -> void:
	if _creature and _new_skill:
		_creature.replace_skill(slot_index, _new_skill)
	visible = false
	skill_replaced.emit(slot_index)

func _on_cancel() -> void:
	visible = false
	skill_cancelled.emit()
