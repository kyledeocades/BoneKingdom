extends CanvasLayer
## Bone Kingdom – Win / Lose Result Overlay
## Spawned by GameController; call show_result("YOU WIN") or show_result("YOU LOSE")
## ⚠ Adjust MAIN_MENU_PATH to match your main menu scene path

class_name GameResultOverlay

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

const C_BONE    := Color("#E8D5A3")
const C_GOLD    := Color("#C9A84C")
const C_GOLD_DIM:= Color("#7A6030")
const C_CRIMSON := Color("#8B1A1A")
const C_ASH     := Color("#5A4E3A")
const C_PANEL   := Color("#110D08")

const C_WIN_BG  := Color("#0A0D08")
const C_WIN_BOR := Color("#C9A84C")
const C_LOSE_BG := Color("#0D0806")
const C_LOSE_BOR:= Color("#6B1212")

# ─── Spacing ───────────────────────────────────────────────────────────────
const MARGIN_HORIZ = 56
const MARGIN_VERT  = 60
const SPACER_ICON_BOTTOM = 8
const SPACER_TITLE_BOTTOM = 6
const SPACER_DIVIDER_BOTTOM = 10
const SPACER_MESSAGE_BOTTOM = 44
const SPACER_BUTTON_GAP = 16
const BUTTON_WIDTH = 320
const BUTTON_HEIGHT = 56

var _panel:        PanelContainer
var _icon_label:   Label
var _result_label: Label
var _sub_label:    Label
var _buttons:      Array[Button] = []

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()

func _build_ui() -> void:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dim — add to tree FIRST, then set preset so parent rect is known
	var dim := ColorRect.new()
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	# Center container — keeps the panel locked to the viewport center
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Panel — PanelContainer auto-sizes from content, CenterContainer handles placement
	_panel = PanelContainer.new()
	_panel.name = "ResultPanel"
	_panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", MARGIN_HORIZ)
	margin.add_theme_constant_override("margin_right", MARGIN_HORIZ)
	margin.add_theme_constant_override("margin_top", MARGIN_VERT)
	margin.add_theme_constant_override("margin_bottom", MARGIN_VERT)
	_panel.add_child(margin)

	# VBox — ALIGNMENT_BEGIN (default); ALIGNMENT_CENTER needs a defined
	# height or items render at the wrong position
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)

	# ── Content ──────────────────────────────────────────────────────────────
	_icon_label = Label.new()
	_icon_label.text = "💀"
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 62)
	vbox.add_child(_icon_label)

	_add_spacer(vbox, SPACER_ICON_BOTTOM)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 64)
	_result_label.add_theme_color_override("font_color", C_BONE)
	vbox.add_child(_result_label)

	_add_spacer(vbox, SPACER_TITLE_BOTTOM)

	var divider := ColorRect.new()
	divider.name = "Divider"
	divider.color = C_GOLD_DIM
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	_add_spacer(vbox, SPACER_DIVIDER_BOTTOM)

	_sub_label = Label.new()
	_sub_label.text = ""
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.add_theme_font_size_override("font_size", 16)
	_sub_label.add_theme_color_override("font_color", C_ASH)
	_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_sub_label)

	_add_spacer(vbox, SPACER_MESSAGE_BOTTOM)

	var menu_btn := _make_button("⌂   MAIN MENU", C_CRIMSON, C_BONE)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	_buttons.append(menu_btn)
	vbox.add_child(menu_btn)

	_add_spacer(vbox, SPACER_BUTTON_GAP)

	var quit_btn := _make_button("✕   QUIT", C_PANEL, C_ASH)
	quit_btn.pressed.connect(_on_quit_pressed)
	_buttons.append(quit_btn)
	vbox.add_child(quit_btn)

	_setup_button_focus_navigation()

# ── Focus Navigation ────────────────────────────────────────────────────────────

func _setup_button_focus_navigation() -> void:
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		var prev = _buttons[i - 1] if i > 0 else _buttons[-1]
		var next = _buttons[(i + 1) % _buttons.size()]
		btn.focus_previous = btn.get_path_to(prev)
		btn.focus_next = btn.get_path_to(next)

# ── Public API ────────────────────────────────────────────────────────────────

func show_result(result: String) -> void:
	var is_win := (result == "YOU WIN")

	if _icon_label:
		_icon_label.text = "👑" if is_win else "💀"
	if _result_label:
		_result_label.text = "VICTORY" if is_win else "DEFEAT"
		_result_label.add_theme_color_override("font_color",
			C_GOLD if is_win else C_CRIMSON)
	if _sub_label:
		_sub_label.text = "The kingdom kneels before you." if is_win \
			else "Your bones shall feed the enemy."

	var divider := find_child("Divider", true, false)
	if divider:
		divider.color = C_GOLD if is_win else C_LOSE_BOR

	if _panel:
		var style := StyleBoxFlat.new()
		style.bg_color  = C_WIN_BG  if is_win else C_LOSE_BG
		style.set_border_width_all(2)
		style.border_color = C_WIN_BOR if is_win else C_LOSE_BOR
		style.set_corner_radius_all(4)
		_panel.add_theme_stylebox_override("panel", style)

	show()
	if _buttons.size() > 0:
		_buttons[0].grab_focus()

	if _panel:
		_panel.modulate = Color(1, 1, 1, 0)
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.5) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if _icon_label:
		await get_tree().create_timer(0.5, false, false, true).timeout
		var bounce := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops()
		bounce.tween_property(_icon_label, "position:y", -8.0, 0.7) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		bounce.tween_property(_icon_label, "position:y", 0.0, 0.7) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_button(label_text: String, bg: Color, fg: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	btn.add_theme_font_size_override("font_size", 18)
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

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
