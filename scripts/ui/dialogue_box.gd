extends CanvasLayer

## Dialogue box with typewriter text, speaker name tab, and blinking triangle indicator.

@onready var panel: PanelContainer = $Panel
@onready var text_label: Label = $Panel/MarginContainer/VBox/TextLabel
@onready var continue_label: Label = $Panel/MarginContainer/VBox/ContinueLabel

var _lines: Array[String] = []
var _current_line := 0
var _is_typing := false
var _on_complete: Callable
var _full_text := ""
var _visible_chars := 0.0
var _speaker_name := ""

var _btn_row: HBoxContainer
var _next_btn: Button
var _close_btn: Button
var _speaker_label: Label
var _triangle_label: Label
var _triangle_time := 0.0

const CHARS_PER_SECOND := 30.0

func _ready() -> void:
	add_to_group("dialogue_box")
	panel.visible = false
	continue_label.visible = false

	# Speaker name tab above dialogue panel
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 9)
	_speaker_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	_speaker_label.visible = false
	_speaker_label.position = Vector2(10, -14)
	panel.add_child(_speaker_label)

	# Blinking triangle "next" indicator
	_triangle_label = Label.new()
	_triangle_label.text = "\u25bc"
	_triangle_label.add_theme_font_size_override("font_size", 10)
	_triangle_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	_triangle_label.visible = false
	_triangle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_triangle_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	_triangle_label.anchor_left = 1.0
	_triangle_label.anchor_top = 1.0
	_triangle_label.anchor_right = 1.0
	_triangle_label.anchor_bottom = 1.0
	_triangle_label.offset_left = -24
	_triangle_label.offset_top = -16
	_triangle_label.offset_right = -4
	_triangle_label.offset_bottom = -2
	panel.add_child(_triangle_label)

	# Add clickable buttons (smaller, right-aligned)
	_btn_row = HBoxContainer.new()
	_btn_row.alignment = BoxContainer.ALIGNMENT_END
	_btn_row.add_theme_constant_override("separation", 6)
	_btn_row.visible = false
	$Panel/MarginContainer/VBox.add_child(_btn_row)

	_next_btn = Button.new()
	_next_btn.text = "Next"
	_next_btn.custom_minimum_size = Vector2(50, 20)
	_next_btn.add_theme_font_size_override("font_size", 9)
	_next_btn.pressed.connect(_on_next_pressed)
	_btn_row.add_child(_next_btn)

	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.custom_minimum_size = Vector2(50, 20)
	_close_btn.add_theme_font_size_override("font_size", 9)
	_close_btn.pressed.connect(_on_close_pressed)
	_btn_row.add_child(_close_btn)

func show_dialogue(lines: Array, on_complete: Callable = Callable(), speaker: String = "") -> void:
	_lines.clear()
	for line in lines:
		_lines.append(str(line))
	_current_line = 0
	_on_complete = on_complete
	_speaker_name = speaker
	panel.visible = true

	# Show speaker name if provided
	if _speaker_name != "":
		_speaker_label.text = _speaker_name
		_speaker_label.visible = true
	else:
		_speaker_label.visible = false

	ThemeManager.animate_panel_open(panel)
	_show_current_line()

func _show_current_line() -> void:
	if _current_line >= _lines.size():
		_close()
		return
	_full_text = _lines[_current_line]
	text_label.text = ""
	_visible_chars = 0.0
	_is_typing = true
	continue_label.visible = false
	_btn_row.visible = false
	_triangle_label.visible = false

func _process(delta: float) -> void:
	if _is_typing:
		_visible_chars += CHARS_PER_SECOND * delta
		var char_count := int(_visible_chars)
		if char_count >= _full_text.length():
			text_label.text = _full_text
			_is_typing = false
			_show_buttons()
		else:
			text_label.text = _full_text.substr(0, char_count)

	# Blink triangle indicator
	if _triangle_label.visible:
		_triangle_time += delta * 3.0
		_triangle_label.modulate.a = 0.4 + sin(_triangle_time) * 0.4

func _show_buttons() -> void:
	_btn_row.visible = true
	_next_btn.visible = _current_line < _lines.size() - 1
	_triangle_label.visible = _current_line < _lines.size() - 1
	continue_label.visible = false

func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
		return
	if event.is_action_pressed("ui_accept"):
		if _is_typing:
			text_label.text = _full_text
			_is_typing = false
			_show_buttons()
		else:
			_current_line += 1
			_show_current_line()

func _on_next_pressed() -> void:
	if _is_typing:
		text_label.text = _full_text
		_is_typing = false
		_show_buttons()
	else:
		_current_line += 1
		_show_current_line()

func _on_close_pressed() -> void:
	_close()

func _close() -> void:
	ThemeManager.animate_panel_close(panel)
	_btn_row.visible = false
	_triangle_label.visible = false
	_speaker_label.visible = false
	_is_typing = false
	if _on_complete.is_valid():
		_on_complete.call()
