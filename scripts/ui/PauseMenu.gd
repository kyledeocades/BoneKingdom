extends CanvasLayer
## Bone Kingdom – Pause Menu Overlay
## Spawned by GameController; toggled via open() / close()
## ⚠ Adjust MAIN_MENU_PATH to match your main menu scene path

class_name PauseMenu

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

# ── Colors ───────────────────────────────────────────────────────────────────
const C_BONE    := Color("#E8D5A3")
const C_GOLD    := Color("#C9A84C")
const C_GOLD_DIM:= Color("#7A6030")
const C_CRIMSON := Color("#8B1A1A")
const C_ASH     := Color("#5A4E3A")
const C_PANEL   := Color("#110D08")
const C_BG      := Color("#160F09")

# ── Fonts ──────────────────────────────────────────────────────────────────────
const FONT_TITLE := preload("res://data/fonts/Jacquard/Jacquard24-Regular.ttf")
const FONT_UI    := preload("res://data/fonts/Jersey/Jersey10-Regular.ttf")

# ── Spacing ───────────────────────────────────────────────────────────────────
const MARGIN_HORIZ = 48
const MARGIN_VERT  = 52
const SPACER_SKULL_BOTTOM = 4
const SPACER_TITLE_BOTTOM = 8
const SPACER_DIVIDER_BOTTOM = 28
const SPACER_BUTTON_GAP = 14
const SPACER_BUTTONS_BOTTOM = 28
const BUTTON_WIDTH = 304
const BUTTON_HEIGHT = 54

var _panel: PanelContainer
var _buttons: Array[Button] = []
var _settings_screen: SettingsScreen

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	
	# Create settings screen
	_settings_screen = SettingsScreen.new()
	add_child(_settings_screen)
	
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dim — add to tree FIRST, then set preset so parent rect is known
	var dim := ColorRect.new()
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	# Center container — keeps the panel locked to the viewport center
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Panel — PanelContainer auto-sizes from content, CenterContainer handles placement
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(400, 0)
	_apply_panel_style(_panel, C_BG, C_GOLD_DIM)
	center.add_child(_panel)

	# Inner layout
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", MARGIN_HORIZ)
	margin.add_theme_constant_override("margin_right", MARGIN_HORIZ)
	margin.add_theme_constant_override("margin_top", MARGIN_VERT)
	margin.add_theme_constant_override("margin_bottom", MARGIN_VERT)
	_panel.add_child(margin)

	# VBox — leave at default ALIGNMENT_BEGIN; ALIGNMENT_CENTER needs a
	# defined height or items land in wrong place
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)

	# ── Content ──────────────────────────────────────────────────────────────
	var skull := Label.new()
	skull.text = "💀"
	skull.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER	
	skull.add_theme_font_override("font", FONT_UI)	
	skull.add_theme_font_size_override("font_size", 34)
	vbox.add_child(skull)

	_add_spacer(vbox, SPACER_SKULL_BOTTOM)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", C_BONE)
	vbox.add_child(title)

	_add_spacer(vbox, SPACER_TITLE_BOTTOM)

	var divider := ColorRect.new()
	divider.color = C_GOLD_DIM
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	_add_spacer(vbox, SPACER_DIVIDER_BOTTOM)

	var resume_btn := _make_button("▶   RESUME", C_CRIMSON, C_BONE)
	resume_btn.pressed.connect(_on_resume_pressed)
	_buttons.append(resume_btn)
	vbox.add_child(resume_btn)

	_add_spacer(vbox, SPACER_BUTTON_GAP)

	var restart_btn := _make_button("↻   RESTART", C_PANEL, C_ASH)
	restart_btn.pressed.connect(_on_restart_pressed)
	_buttons.append(restart_btn)
	vbox.add_child(restart_btn)

	_add_spacer(vbox, SPACER_BUTTON_GAP)

	var settings_btn := _make_button("⚙   SETTINGS", C_PANEL, C_ASH)
	settings_btn.pressed.connect(_on_settings_pressed)
	_buttons.append(settings_btn)
	vbox.add_child(settings_btn)

	_add_spacer(vbox, SPACER_BUTTON_GAP)

	var menu_btn := _make_button("⌂   MAIN MENU", C_PANEL, C_ASH)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	_buttons.append(menu_btn)
	vbox.add_child(menu_btn)

	_add_spacer(vbox, SPACER_BUTTON_GAP)

	var quit_btn := _make_button("✕   QUIT GAME", C_PANEL, C_ASH)
	quit_btn.pressed.connect(_on_quit_pressed)
	_buttons.append(quit_btn)
	vbox.add_child(quit_btn)

	_add_spacer(vbox, SPACER_BUTTONS_BOTTOM)

	var hint := Label.new()
	hint.text = "ESC to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", FONT_UI)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(C_ASH, 0.55))
	vbox.add_child(hint)

	# Setup keyboard navigation between buttons
	_setup_button_focus_navigation()

# ── Focus Navigation ──────────────────────────────────────────────────────────

func _setup_button_focus_navigation() -> void:
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		var prev = _buttons[i - 1] if i > 0 else _buttons[-1]
		var next = _buttons[(i + 1) % _buttons.size()]
		btn.focus_previous = btn.get_path_to(prev)
		btn.focus_next = btn.get_path_to(next)

# ── Public API ────────────────────────────────────────────────────────────────

func open() -> void:
	get_tree().paused = true
	show()
	if _buttons.size() > 0:
		_buttons[0].grab_focus()
	_panel.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.20).set_ease(Tween.EASE_OUT)

func close() -> void:
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.15).set_ease(Tween.EASE_IN)
	await tw.finished
	get_tree().paused = false
	hide()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _apply_panel_style(panel: PanelContainer, bg: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(2)
	style.border_color = border
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)

func _make_button(label_text: String, bg: Color, fg: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	btn.add_theme_font_override("font", FONT_UI)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", C_GOLD)
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(1)
	normal.border_color = C_GOLD_DIM
	normal.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = bg.lightened(0.18)
	hover.set_border_width_all(2)
	hover.border_color = C_GOLD
	hover.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_s := StyleBoxFlat.new()
	pressed_s.bg_color = bg.darkened(0.2)
	pressed_s.set_border_width_all(2)
	pressed_s.border_color = C_GOLD
	pressed_s.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("pressed", pressed_s)

	return btn

func _add_spacer(parent: Control, height: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	parent.add_child(s)

# ── Handlers ─────────────────────────────────────────────────────────────────

func _on_resume_pressed() -> void:
	close()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_settings_pressed() -> void:
	_settings_screen.open()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
