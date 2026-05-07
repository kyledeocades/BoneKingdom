extends CanvasLayer
## Settings menu for volume controls
## Can be used as a standalone scene or spawned as an overlay

class_name SettingsScreen

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

# ── Audio Bus Indices ────────────────────────────────────────────────────────
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

var _panel: PanelContainer
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _master_percent_label: Label
var _music_percent_label: Label
var _sfx_percent_label: Label

signal closed

func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
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
	
	# Semi-transparent dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	
	# Centered panel
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(400, 350)
	center.add_child(_panel)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = C_BG
	panel_style.border_color = C_GOLD_DIM
	panel_style.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", panel_style)
	
	# VBox for content
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)
	
	# Add margins
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	vbox.add_child(margin)
	
	var content_vbox := VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(content_vbox)
	
	# Title
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", C_BONE)
	content_vbox.add_child(title)
	
	# Divider
	content_vbox.add_child(_make_divider(C_GOLD_DIM))
	
	# Master Volume
	_master_slider = HSlider.new()
	_master_percent_label = _make_volume_control("Master Volume", _master_slider, content_vbox)
	
	# Music Volume
	_music_slider = HSlider.new()
	_music_percent_label = _make_volume_control("Music Volume", _music_slider, content_vbox)
	
	# SFX Volume
	_sfx_slider = HSlider.new()
	_sfx_percent_label = _make_volume_control("SFX Volume", _sfx_slider, content_vbox)
	
	# Space before button
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	content_vbox.add_child(spacer)
	
	# Close button
	var close_btn := _make_button("CLOSE", C_PANEL, C_ASH)
	close_btn.pressed.connect(close)
	content_vbox.add_child(close_btn)
	
	# Connect slider signals
	_master_slider.value_changed.connect(_on_master_volume_changed)
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Initialize sliders with current values
	_load_volume_settings()

func _make_volume_control(label_text: String, slider: HSlider, container: Container) -> Label:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	# Label
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(label)
	
	# HBox for slider and percentage
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)
	
	# Configure slider
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.custom_minimum_size = Vector2(280, 0)
	hbox.add_child(slider)
	
	# Percentage label
	var percent_label := Label.new()
	percent_label.text = "100%"
	percent_label.custom_minimum_size = Vector2(40, 0)
	percent_label.add_theme_font_override("font", FONT_UI)
	percent_label.add_theme_font_size_override("font_size", 24)
	percent_label.add_theme_color_override("font_color", C_ASH)
	hbox.add_child(percent_label)
	
	# Update percentage when slider changes
	slider.value_changed.connect(func(val):
		if val <= 0:
			percent_label.text = "MUTE"
		else:
			# Normalize slider to 0-1 range
			var norm = val / 100.0
			
			# Apply logarithmic curve (quadratic for good feel)
			var log_norm = pow(norm, 1.5)
			
			# Map to display percentage (0-125%)
			var percent = log_norm * 125.0
			
			# Snap to 100% if within 5%
			if abs(percent - 100.0) < 5.0:
				percent = 100.0
			
			percent_label.text = "%d%%" % int(percent)
	)
	
	container.add_child(vbox)
	return percent_label

func _make_divider(color: Color) -> ColorRect:
	var divider := ColorRect.new()
	divider.color = color
	divider.custom_minimum_size = Vector2(0, 1)
	return divider

func _make_button(text: String, bg_color: Color, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 40)
	
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = bg_color.lightened(0.2)
	hover_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = bg_color.darkened(0.2)
	pressed_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.add_theme_font_override("font", FONT_UI)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_font_size_override("font_size", 24)
	
	return btn

func _load_volume_settings() -> void:
	var master_index = AudioServer.get_bus_index(MASTER_BUS)
	var music_index = AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_index = AudioServer.get_bus_index(SFX_BUS)
	
	if master_index >= 0:
		var db = AudioServer.get_bus_volume_db(master_index)
		_master_slider.value = _db_to_slider_value(db)
		_update_percent_label(db, _master_percent_label)
	if music_index >= 0:
		var db = AudioServer.get_bus_volume_db(music_index)
		_music_slider.value = _db_to_slider_value(db)
		_update_percent_label(db, _music_percent_label)
	if sfx_index >= 0:
		var db = AudioServer.get_bus_volume_db(sfx_index)
		_sfx_slider.value = _db_to_slider_value(db)
		_update_percent_label(db, _sfx_percent_label)

func _update_percent_label(db: float, label: Label) -> void:
	if db <= -80:
		label.text = "MUTE"
	else:
		# Find the slider position that gives this dB value
		var linear_amp = pow(10.0, db / 20.0)
		var max_amp = pow(10.0, 5.0 / 20.0)
		var norm = linear_amp / max_amp
		var log_norm = pow(norm, 1.0 / 1.5)
		var percent = log_norm * 125.0
		
		if abs(percent - 100.0) < 5.0:
			percent = 100.0
		
		label.text = "%d%%" % int(clamp(percent, 0.0, 125.0))

func _slider_value_to_db(slider_value: float) -> float:
	if slider_value <= 0:
		return -80.0  # Mute
	
	# Normalize slider to 0-1 range
	var norm = slider_value / 100.0
	
	# Apply logarithmic curve (quadratic for good feel)
	var log_norm = pow(norm, 1.5)
	
	# Map to dB range: -40 to 5
	return -40.0 + log_norm * 45.0

func _db_to_slider_value(db: float) -> float:
	if db <= -80:
		return 0.0
	
	# Reverse the logarithmic mapping
	var log_norm = (db + 40.0) / 45.0
	var norm = pow(log_norm, 1.0 / 1.5)
	return clamp(norm * 100.0, 0.0, 100.0)

func _on_master_volume_changed(value: float) -> void:
	var db = _slider_value_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), db)
	_update_percent_label(db, _master_percent_label)

func _on_music_volume_changed(value: float) -> void:
	var db = _slider_value_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), db)
	_update_percent_label(db, _music_percent_label)

func _on_sfx_volume_changed(value: float) -> void:
	var db = _slider_value_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), db)
	_update_percent_label(db, _sfx_percent_label)

func open() -> void:
	show()
	_load_volume_settings()

func close() -> void:
	hide()
	closed.emit()
