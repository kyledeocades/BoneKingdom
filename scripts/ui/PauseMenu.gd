extends CanvasLayer
## Bone Kingdom – Pause Menu Overlay
## Spawned by GameController; toggled via open() / close()
## ⚠ Adjust MAIN_MENU_PATH to match your main menu scene path

class_name PauseMenu

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

const C_BONE    := Color("#E8D5A3")
const C_GOLD    := Color("#C9A84C")
const C_GOLD_DIM:= Color("#7A6030")
const C_CRIMSON := Color("#8B1A1A")
const C_ASH     := Color("#5A4E3A")
const C_PANEL   := Color("#110D08")
const C_BG      := Color("#160F09")

var _panel: Panel

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()

func _build_ui() -> void:
	# Dim — add to tree FIRST, then set preset so parent rect is known
	var dim := ColorRect.new()
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	# Panel — direct CanvasLayer child, content drives its size,
	# _center_panel() positions it after layout runs
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(400, 0)
	_apply_panel_style(_panel, C_BG, C_GOLD_DIM)
	add_child(_panel)

	# Inner layout — no PRESET_FULL_RECT inside a content-driven Panel
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 52)
	margin.add_theme_constant_override("margin_bottom", 52)
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
	skull.add_theme_font_size_override("font_size", 34)
	vbox.add_child(skull)

	_add_spacer(vbox, 4)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", C_BONE)
	vbox.add_child(title)

	_add_spacer(vbox, 8)

	var divider := ColorRect.new()
	divider.color = C_GOLD_DIM
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	_add_spacer(vbox, 28)

	var resume_btn := _make_button("▶   RESUME", C_CRIMSON, C_BONE)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	_add_spacer(vbox, 14)

	var menu_btn := _make_button("⌂   MAIN MENU", C_PANEL, C_ASH)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(menu_btn)

	_add_spacer(vbox, 14)

	var quit_btn := _make_button("✕   QUIT GAME", C_PANEL, C_ASH)
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	_add_spacer(vbox, 28)

	var hint := Label.new()
	hint.text = "ESC to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(C_ASH, 0.55))
	vbox.add_child(hint)

	# Defer centering: layout runs after _ready() returns, so minimum sizes
	# aren't final until the next idle frame
	call_deferred("_center_panel")

# ── Centering ─────────────────────────────────────────────────────────────────

func _center_panel() -> void:
	if not is_instance_valid(_panel):
		return
	var vp_size := get_viewport().get_visible_rect().size
	var min_sz   := _panel.get_combined_minimum_size()
	_panel.size     = min_sz
	_panel.position = ((vp_size - min_sz) * 0.5).round()

# ── Public API ────────────────────────────────────────────────────────────────

func open() -> void:
	_center_panel()   # Re-center in case viewport changed
	get_tree().paused = true
	show()
	_panel.modulate = Color(1, 1, 1, 0)
	_panel.scale    = Vector2(0.90, 0.90)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.20).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.20) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func close() -> void:
	get_tree().paused = false
	hide()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _apply_panel_style(panel: Panel, bg: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(2)
	style.border_color = border
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)

func _make_button(label_text: String, bg: Color, fg: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(304, 54)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", C_GOLD)
	btn.focus_mode = Control.FOCUS_NONE
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

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
