extends Control
## Stage selection screen displayed after "Play" is pressed in main menu
## Shows all available stages and allows player to select one

class_name StageSelectScreen

# ── Scene Path ─────────────────────────────────────────────────────────────────
const GAME_SCENE_PATH := "res://scenes/Main.tscn"

# ── Palette ────────────────────────────────────────────────────────────────────
const C_BG      := Color("#0C0906")
const C_BONE    := Color("#E8D5A3")
const C_GOLD    := Color("#C9A84C")
const C_GOLD_DIM:= Color("#7A6030")
const C_CRIMSON := Color("#8B1A1A")
const C_ASH     := Color("#5A4E3A")
const C_PANEL   := Color("#16100A")

# ── Fonts ──────────────────────────────────────────────────────────────────────
const FONT_TITLE := preload("res://data/fonts/Jacquard/Jacquard24-Regular.ttf")
const FONT_UI    := preload("res://data/fonts/Jersey/Jersey10-Regular.ttf")

var _selected_stage_id: String = ""
var _stage_manager: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_manager = StageManager.new()
	
	# Ensure menu music continues playing
	if MainMenu._menu_music and not MainMenu._menu_music.playing:
		MainMenu._menu_music.play()
	
	_build_ui()

func _build_ui() -> void:
	# ── Deep background ──────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Atmospheric dark vignette overlay
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.28)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	# ── Centered column ───────────────────────────────────────────────────────
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(600, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	center.add_child(vbox)

	# ── Title ─────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "SELECT STAGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", C_BONE)
	vbox.add_child(title)

	_add_spacer(vbox, 12)

	# ── Gold divider ──────────────────────────────────────────────────────────
	vbox.add_child(_make_divider(C_GOLD_DIM))

	_add_spacer(vbox, 32)

	# ── Stage buttons ─────────────────────────────────────────────────────────
	var available_stages = _stage_manager.get_available_stage_configs()
	
	if available_stages.is_empty():
		var no_stages := Label.new()
		no_stages.text = "No stages available"
		no_stages.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_stages.add_theme_font_override("font", FONT_UI)
		no_stages.add_theme_color_override("font_color", C_ASH)
		vbox.add_child(no_stages)
	else:
		for stage in available_stages:
			var stage_btn = _make_stage_button(stage)
			vbox.add_child(stage_btn)
			_add_spacer(vbox, 16)
		
		# No stages label styling
		var no_stages := Label.new()
		no_stages.text = "No stages available"
		no_stages.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_stages.add_theme_font_override("font", FONT_UI)
		no_stages.add_theme_color_override("font_color", C_ASH)

	_add_spacer(vbox, 32)

	# ── Back button ───────────────────────────────────────────────────────────
	var back_btn := _make_button("← BACK", C_PANEL, C_ASH, false)
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)

	_add_spacer(vbox, 52)

# ── Stage Button Creation ──────────────────────────────────────────────────────

func _make_stage_button(stage: StageConfig) -> Button:
	var btn := Button.new()
	btn.text = "%s" % stage.stage_name
	btn.custom_minimum_size = Vector2(400, 70)
	btn.add_theme_font_override("font", FONT_UI)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", C_BONE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", C_GOLD)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal := StyleBoxFlat.new()
	normal.bg_color = C_CRIMSON.darkened(0.2)
	normal.set_border_width_all(2)
	normal.border_color = C_CRIMSON
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = C_CRIMSON
	hover.set_border_width_all(2)
	hover.border_color = C_GOLD
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = C_CRIMSON.lightened(0.2)
	pressed.set_border_width_all(2)
	pressed.border_color = C_GOLD
	pressed.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_stylebox_override("focus", hover)

	# Connect button to stage selection
	btn.pressed.connect(_on_stage_selected.bindv([stage.stage_id]))

	return btn

# ── Button Helpers ────────────────────────────────────────────────────────────

func _make_button(label_text: String, bg: Color, fg: Color, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(360, 60)
	btn.add_theme_font_override("font", FONT_UI)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", C_GOLD)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var border_w := 2 if primary else 1
	var border_c := C_GOLD if primary else C_GOLD_DIM

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(border_w)
	normal.border_color = border_c.darkened(0.35)
	normal.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = bg.lightened(0.18)
	hover.set_border_width_all(2)
	hover.border_color = C_GOLD
	hover.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = bg.darkened(0.25)
	pressed.set_border_width_all(2)
	pressed.border_color = C_GOLD
	pressed.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_stylebox_override("focus", hover)

	return btn

func _make_divider(color: Color) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(line)
	return margin

func _add_spacer(parent: Control, height: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	parent.add_child(s)

# ── Button Actions ────────────────────────────────────────────────────────────

func _on_stage_selected(stage_id: String) -> void:
	_selected_stage_id = stage_id
	print("Stage selected: %s" % stage_id)
	# Pass stage ID to GameController through static variable
	GameController.selected_stage_id = stage_id
	# Stop menu music before transitioning to game
	if MainMenu._menu_music and MainMenu._menu_music.playing:
		MainMenu._menu_music.stop()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_back_pressed() -> void:
	queue_free()
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
