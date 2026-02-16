extends CanvasLayer

## NPC Trade Menu — offline trading with NPC. Player selects a creature,
## NPC offers a comparable one. Stat comparison shown before confirming.
## Trade evolution triggers automatically after trade completes.

signal trade_completed(offered_index: int, received_creature: CreatureInstance)
signal closed

enum TradeState { SELECTING, OFFER_SHOWN, EVOLVING, COMPLETE }

var _state: TradeState = TradeState.SELECTING
var _selected_index: int = -1
var _offered_creature: CreatureInstance
var _npc_offer_data: CreatureData

# UI refs
var _party_vbox: VBoxContainer
var _offer_panel: VBoxContainer
var _confirm_btn: Button
var _status_label: Label
var _comparison_panel: VBoxContainer

# All available species for NPC pool
const SPECIES_PATHS := [
	"res://resources/creatures/flamepup.tres",
	"res://resources/creatures/aquafin.tres",
	"res://resources/creatures/thornsprout.tres",
	"res://resources/creatures/zephyrix.tres",
	"res://resources/creatures/stoneling.tres",
	"res://resources/creatures/blazefox.tres",
	"res://resources/creatures/tidalfin.tres",
	"res://resources/creatures/vinewhisker.tres",
	"res://resources/creatures/breezeling.tres",
	"res://resources/creatures/boulderkin.tres",
	"res://resources/creatures/pyrodrake.tres",
	"res://resources/creatures/tsunamaw.tres",
	"res://resources/creatures/galetalon.tres",
	"res://resources/creatures/dirtmole.tres",
	"res://resources/creatures/cragshell.tres",
	"res://resources/creatures/titanrock.tres",
	"res://resources/creatures/thornlord.tres",
]

func _ready() -> void:
	layer = 50
	_build_ui()

func _build_ui() -> void:
	# Dark backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.7)
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	add_child(backdrop)

	# Center panel
	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_top = -160
	panel.offset_right = 260
	panel.offset_bottom = 160
	add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 6)
	panel.add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = "NPC Trade Center"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	main_vbox.add_child(title)

	# Two columns
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(columns)

	# Left: your party
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	columns.add_child(left)

	var your_label := Label.new()
	your_label.text = "Your Creatures"
	your_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	your_label.add_theme_font_size_override("font_size", 11)
	your_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT)
	left.add_child(your_label)

	_party_vbox = VBoxContainer.new()
	_party_vbox.add_theme_constant_override("separation", 2)
	left.add_child(_party_vbox)
	_populate_party_list()

	# Right: NPC offer + comparison
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 3)
	right.custom_minimum_size.x = 200
	columns.add_child(right)

	var offer_title := Label.new()
	offer_title.text = "NPC Offer"
	offer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_title.add_theme_font_size_override("font_size", 11)
	offer_title.add_theme_color_override("font_color", Color(0.3, 0.85, 0.9))
	right.add_child(offer_title)

	_offer_panel = VBoxContainer.new()
	_offer_panel.add_theme_constant_override("separation", 2)
	right.add_child(_offer_panel)

	var placeholder := Label.new()
	placeholder.text = "Select a creature\nto see offer..."
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 9)
	placeholder.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	_offer_panel.add_child(placeholder)

	# Comparison panel (hidden until offer shown)
	_comparison_panel = VBoxContainer.new()
	_comparison_panel.add_theme_constant_override("separation", 1)
	_comparison_panel.visible = false
	right.add_child(_comparison_panel)

	# Status label
	_status_label = Label.new()
	_status_label.text = "Choose a creature to offer."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
	main_vbox.add_child(_status_label)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(btn_row)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm Trade"
	_confirm_btn.custom_minimum_size = Vector2(100, 28)
	_confirm_btn.visible = false
	_confirm_btn.pressed.connect(_on_confirm_trade)
	btn_row.add_child(_confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(80, 28)
	cancel_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	btn_row.add_child(cancel_btn)
	cancel_btn.grab_focus()

func _populate_party_list() -> void:
	for child in _party_vbox.get_children():
		child.queue_free()

	for i in PartyManager.party.size():
		var creature: CreatureInstance = PartyManager.party[i]
		var btn := Button.new()
		var el_name: String = ThemeManager.ELEMENT_NAMES[creature.data.element]
		var shiny_star := " *" if creature.is_shiny else ""
		btn.text = "%s Lv.%d [%s]%s" % [creature.display_name(), creature.level, el_name, shiny_star]
		btn.custom_minimum_size = Vector2(170, 22)
		btn.add_theme_font_size_override("font_size", 9)
		# Disable fainted creatures
		if creature.is_fainted():
			btn.disabled = true
			btn.text += " (FAINTED)"
		# Disable if only 1 non-fainted creature (can't trade last one)
		elif _count_alive() <= 1:
			btn.disabled = true
			btn.tooltip_text = "Can't trade your last creature!"
		var idx := i
		btn.pressed.connect(func(): _on_select_creature(idx))
		_party_vbox.add_child(btn)

func _count_alive() -> int:
	var count := 0
	for c in PartyManager.party:
		if not c.is_fainted():
			count += 1
	return count

func _on_select_creature(index: int) -> void:
	_selected_index = index
	var player_creature: CreatureInstance = PartyManager.party[index]
	_npc_offer_data = _generate_npc_offer(player_creature)

	if not _npc_offer_data:
		_status_label.text = "No suitable trade found. Try another creature."
		_confirm_btn.visible = false
		return

	# Create the offered creature instance
	var offer_level: int = clampi(player_creature.level + randi_range(-2, 2), 1, 50)
	_offered_creature = CreatureInstance.new(_npc_offer_data, offer_level)
	_offered_creature.roll_shiny()

	# Update state
	_state = TradeState.OFFER_SHOWN
	_confirm_btn.visible = true

	# Show offer
	_show_offer(player_creature)
	_show_comparison(player_creature, _offered_creature)

	_status_label.text = "Trade %s for %s?" % [player_creature.display_name(), _offered_creature.display_name()]
	AudioManager.play_sound(AudioManager.SFX.NPC_INTERACT)

	# Highlight selected button
	for i in _party_vbox.get_child_count():
		var btn: Button = _party_vbox.get_child(i) as Button
		if btn:
			if i == index:
				btn.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GOLD)
			else:
				btn.remove_theme_color_override("font_color")

func _generate_npc_offer(player_creature: CreatureInstance) -> CreatureData:
	var player_rarity: int = player_creature.data.rarity
	var player_element: int = player_creature.data.element
	var candidates: Array[CreatureData] = []

	for path in SPECIES_PATHS:
		var species: CreatureData = load(path) as CreatureData
		if not species:
			continue
		# Skip same species
		if species.species_id == player_creature.data.species_id:
			continue
		# Match rarity ±1
		if abs(species.rarity - player_rarity) > 1:
			continue
		candidates.append(species)

	if candidates.is_empty():
		return null

	# Prioritize species player doesn't own (not caught in dex)
	var unowned: Array[CreatureData] = []
	for c in candidates:
		if DexManager.get_status(c.species_id) != DexManager.DexStatus.CAUGHT:
			unowned.append(c)

	# Also deprioritize same element
	var diff_element: Array[CreatureData] = []
	var pool: Array[CreatureData] = unowned if unowned.size() > 0 else candidates
	for c in pool:
		if c.element != player_element:
			diff_element.append(c)

	var final_pool: Array[CreatureData] = diff_element if diff_element.size() > 0 else pool
	return final_pool[randi() % final_pool.size()]

func _show_offer(player_creature: CreatureInstance) -> void:
	for child in _offer_panel.get_children():
		child.queue_free()

	var name_label := Label.new()
	var shiny_star := " *" if _offered_creature.is_shiny else ""
	name_label.text = "%s Lv.%d%s" % [_offered_creature.display_name(), _offered_creature.level, shiny_star]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	_offer_panel.add_child(name_label)

	# Element badge
	var el_badge := ThemeManager.create_element_badge(_offered_creature.data.element)
	el_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offer_panel.add_child(el_badge)

	# Rarity
	var rarity_names := ["Common", "Uncommon", "Rare", "Legendary"]
	var rarity_colors := [ThemeManager.COL_TEXT_DIM, Color(0.3, 0.8, 0.3), Color(0.3, 0.6, 0.95), ThemeManager.COL_ACCENT_GOLD]
	var rarity_label := Label.new()
	rarity_label.text = rarity_names[_offered_creature.data.rarity]
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 9)
	rarity_label.add_theme_color_override("font_color", rarity_colors[_offered_creature.data.rarity])
	_offer_panel.add_child(rarity_label)

	# Trade evo hint
	if _offered_creature.can_trade_evolve():
		var evo_label := Label.new()
		evo_label.text = ">> Will evolve after trade!"
		evo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		evo_label.add_theme_font_size_override("font_size", 9)
		evo_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		_offer_panel.add_child(evo_label)

func _show_comparison(player_creature: CreatureInstance, npc_creature: CreatureInstance) -> void:
	_comparison_panel.visible = true
	for child in _comparison_panel.get_children():
		child.queue_free()

	var sep := HSeparator.new()
	_comparison_panel.add_child(sep)

	var header := Label.new()
	header.text = "Stat Comparison"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 9)
	header.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	_comparison_panel.add_child(header)

	var stats := [
		["HP", player_creature.max_hp(), npc_creature.max_hp()],
		["ATK", player_creature.attack(), npc_creature.attack()],
		["DEF", player_creature.defense(), npc_creature.defense()],
		["SPD", player_creature.speed(), npc_creature.speed()],
	]

	for stat_entry in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		_comparison_panel.add_child(row)

		var stat_name := Label.new()
		stat_name.text = stat_entry[0]
		stat_name.add_theme_font_size_override("font_size", 9)
		stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_name.custom_minimum_size.x = 30
		row.add_child(stat_name)

		var yours := Label.new()
		yours.text = str(stat_entry[1])
		yours.add_theme_font_size_override("font_size", 9)
		yours.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		yours.custom_minimum_size.x = 30
		row.add_child(yours)

		var arrow := Label.new()
		arrow.text = " > "
		arrow.add_theme_font_size_override("font_size", 9)
		row.add_child(arrow)

		var theirs := Label.new()
		theirs.text = str(stat_entry[2])
		theirs.add_theme_font_size_override("font_size", 9)
		theirs.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		theirs.custom_minimum_size.x = 30
		# Color code: green if better, red if worse
		if stat_entry[2] > stat_entry[1]:
			theirs.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_GREEN)
		elif stat_entry[2] < stat_entry[1]:
			theirs.add_theme_color_override("font_color", ThemeManager.COL_ACCENT_RED)
		row.add_child(theirs)

func _on_confirm_trade() -> void:
	if _selected_index < 0 or not _offered_creature:
		return

	_state = TradeState.COMPLETE
	_confirm_btn.disabled = true

	# Play trade SFX
	AudioManager.play_sound(AudioManager.SFX.TRADE_COMPLETE)

	# Remove offered creature from party
	var traded_away: CreatureInstance = PartyManager.party[_selected_index]
	PartyManager.party.remove_at(_selected_index)

	# Mark NPC creature as caught in dex
	DexManager.mark_caught(_offered_creature.data.species_id)

	# Check for trade evolution on received creature
	if _offered_creature.can_trade_evolve():
		_state = TradeState.EVOLVING
		_status_label.text = "%s is evolving..." % _offered_creature.display_name()
		AudioManager.play_sound(AudioManager.SFX.EVOLVE_SPARKLE)
		# Small delay for evolution
		await get_tree().create_timer(1.0).timeout
		_offered_creature.trade_evolve()
		DexManager.mark_caught(_offered_creature.data.species_id)
		_status_label.text = "%s evolved into %s!" % [traded_away.display_name(), _offered_creature.display_name()]
		AudioManager.play_sound(AudioManager.SFX.EVOLVE_COMPLETE)
		# Tutorial: trade evolution
		if TutorialManager and not TutorialManager.is_completed("trade_evolution"):
			TutorialManager.show_tutorial("trade_evolution")
	else:
		_status_label.text = "Trade complete! Received %s." % _offered_creature.display_name()

	# Add received creature to party
	PartyManager.add_creature(_offered_creature)

	# Track stats and quests
	StatsManager.increment("trades_completed")
	QuestManager.increment_quest("complete_trade")

	# Emit signal
	trade_completed.emit(_selected_index, _offered_creature)

	# Update UI after short delay
	await get_tree().create_timer(1.5).timeout
	_status_label.text = "Trade done! Close when ready."
	_confirm_btn.visible = false
	_populate_party_list()
