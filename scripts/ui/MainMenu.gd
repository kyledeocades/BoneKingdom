extends Control
## Bone Kingdom – Main Menu
## Built entirely in code; attach to a full-screen Control node as root of MainMenu.tscn
## ⚠ Adjust GAME_SCENE_PATH to match your actual game scene path

class_name MainMenu

# ── Scene Path ─────────────────────────────────────────────────────────────────
const GAME_SCENE_PATH := "res://scenes/Main.tscn"  # ← change to your game scene

# ── Palette ────────────────────────────────────────────────────────────────────
const C_BG      := Color("#0C0906")
const C_BONE    := Color("#E8D5A3")
const C_GOLD    := Color("#C9A84C")
const C_GOLD_DIM:= Color("#7A6030")
const C_CRIMSON := Color("#8B1A1A")
const C_ASH     := Color("#5A4E3A")
const C_PANEL   := Color("#16100A")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	vbox.custom_minimum_size = Vector2(500, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	center.add_child(vbox)

	# ── Skull ornament ────────────────────────────────────────────────────────
	var skulls := Label.new()
	skulls.text = "☠                    ☠"
	skulls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skulls.add_theme_font_size_override("font_size", 22)
	skulls.add_theme_color_override("font_color", C_GOLD_DIM)
	vbox.add_child(skulls)

	_add_spacer(vbox, 8)

	# ── BONE KINGDOM title ────────────────────────────────────────────────────
	var title := Label.new()
	title.name = "Title"
	title.text = "BONE\nKINGDOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", C_BONE)
	title.add_theme_constant_override("line_separation", -10)
	vbox.add_child(title)

	_add_spacer(vbox, 6)

	# ── Gold divider ──────────────────────────────────────────────────────────
	vbox.add_child(_make_divider(C_GOLD_DIM))

	_add_spacer(vbox, 10)

	# ── Tagline ───────────────────────────────────────────────────────────────
	var tagline := Label.new()
	tagline.text = "Rule the dead. Crush the living."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 15)
	tagline.add_theme_color_override("font_color", C_ASH)
	vbox.add_child(tagline)

	_add_spacer(vbox, 64)

	# ── PLAY button ───────────────────────────────────────────────────────────
	var play_btn := _make_button("⚔   PLAY", C_CRIMSON, C_BONE, true)
	play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(play_btn)

	_add_spacer(vbox, 16)

	# ── QUIT button ───────────────────────────────────────────────────────────
	var quit_btn := _make_button("✕   QUIT", C_PANEL, C_ASH, false)
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	_add_spacer(vbox, 52)

	# ── Footer hint ───────────────────────────────────────────────────────────
	var footer := Label.new()
	footer.text = "Press  ESC  during battle to pause"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", Color(C_ASH, 0.6))
	vbox.add_child(footer)

	# ── Start title pulse animation ───────────────────────────────────────────
	_start_title_pulse(title)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_button(label_text: String, bg: Color, fg: Color, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(360, 60)
	btn.add_theme_font_size_override("font_size", 22)
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

	# Focus style (same as hover)
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

func _start_title_pulse(title: Label) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(title, "modulate", Color(1.0, 1.0, 1.0, 0.7), 2.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ── Actions ───────────────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
