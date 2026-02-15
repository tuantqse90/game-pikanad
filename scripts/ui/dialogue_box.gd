extends CanvasLayer

## Dialogue box with typewriter text effect.

@onready var panel: PanelContainer = $Panel
@onready var text_label: Label = $Panel/MarginContainer/VBox/TextLabel
@onready var continue_label: Label = $Panel/MarginContainer/VBox/ContinueLabel

var _lines: Array[String] = []
var _current_line := 0
var _is_typing := false
var _on_complete: Callable
var _full_text := ""
var _visible_chars := 0.0

const CHARS_PER_SECOND := 30.0

func _ready() -> void:
	add_to_group("dialogue_box")
	panel.visible = false
	continue_label.text = "[ENTER]"
	continue_label.visible = false

func show_dialogue(lines: Array, on_complete: Callable = Callable()) -> void:
	_lines.clear()
	for line in lines:
		_lines.append(str(line))
	_current_line = 0
	_on_complete = on_complete
	panel.visible = true
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

func _process(delta: float) -> void:
	if not _is_typing:
		return
	_visible_chars += CHARS_PER_SECOND * delta
	var char_count := int(_visible_chars)
	if char_count >= _full_text.length():
		text_label.text = _full_text
		_is_typing = false
		continue_label.visible = true
	else:
		text_label.text = _full_text.substr(0, char_count)

func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("ui_accept"):
		if _is_typing:
			# Skip typewriter, show full text
			text_label.text = _full_text
			_is_typing = false
			continue_label.visible = true
		else:
			# Advance to next line
			_current_line += 1
			_show_current_line()

func _close() -> void:
	panel.visible = false
	_is_typing = false
	if _on_complete.is_valid():
		_on_complete.call()
