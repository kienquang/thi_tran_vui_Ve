extends Control

func _ready():
	var title_font = DynamicFont.new()
	title_font.font_data = load("res://assets/VT323-Regular.ttf")
	title_font.size = 48 # Font pixel thường cần kích thước lớn hơn một chút để rõ nét
	
	var btn_font = DynamicFont.new()
	btn_font.font_data = load("res://assets/ARIAL.TTF")
	btn_font.size = 16
	
	$CenterContainer/Panel/VBoxContainer/Label.add_font_override("font", title_font)
	$CenterContainer/Panel/VBoxContainer/Label.add_color_override("font_color", Color(0.25, 0.15, 0.05))
	
	var continue_btn = $CenterContainer/Panel/VBoxContainer/ContinueButton
	var start_btn = $CenterContainer/Panel/VBoxContainer/StartButton
	var settings_btn = $CenterContainer/Panel/VBoxContainer/SettingsButton
	var quit_btn = $CenterContainer/Panel/VBoxContainer/QuitButton
	
	continue_btn.add_font_override("font", btn_font)
	start_btn.add_font_override("font", btn_font)
	settings_btn.add_font_override("font", btn_font)
	quit_btn.add_font_override("font", btn_font)
	
	continue_btn.connect("pressed", self, "_on_continue_pressed")
	start_btn.connect("pressed", self, "_on_start_pressed")
	settings_btn.connect("pressed", self, "_on_settings_pressed")
	quit_btn.connect("pressed", self, "_on_quit_pressed")
	
	if SaveManager.has_save():
		continue_btn.show()
	else:
		continue_btn.hide()
	
	# Cập nhật tên game
	$CenterContainer/Panel/VBoxContainer/Label.text = "THỊ TRẤN BẤT ỔN"
	
	# Sử dụng khung tiêu đề cho Label
	var title_tex = load("res://assets/others/formal_dialog_input_frame_v1_1024x192.png")
	if title_tex:
		var title_style = StyleBoxTexture.new()
		title_style.texture = title_tex
		title_style.margin_left = 40
		title_style.margin_right = 40
		title_style.margin_top = 20
		title_style.margin_bottom = 20
		$CenterContainer/Panel/VBoxContainer/Label.add_stylebox_override("normal", title_style)
	
	# Sử dụng panel base cho menu chính
	var panel_tex = load("res://assets/others/formal_dialog_panel_base_v1_1024x640.png")
	if panel_tex:
		var style = StyleBoxTexture.new()
		style.texture = panel_tex
		style.margin_left = 60
		style.margin_right = 60
		style.margin_top = 60
		style.margin_bottom = 60
		$CenterContainer/Panel.add_stylebox_override("panel", style)
		
	# Bọc các nút bấm bằng assets
	var btn_tex = load("res://assets/others/resident_message_close_button_v2.png")
	if btn_tex:
		var btn_style = StyleBoxTexture.new()
		btn_style.texture = btn_tex
		btn_style.margin_left = 10
		btn_style.margin_right = 10
		btn_style.margin_top = 10
		btn_style.margin_bottom = 10
		
		var hover_style = btn_style.duplicate()
		hover_style.modulate_color = Color(1.2, 1.2, 1.2) # Sáng lên khi hover
		
		var pressed_style = btn_style.duplicate()
		pressed_style.modulate_color = Color(0.8, 0.8, 0.8) # Tối đi khi ấn
		
		for btn in [continue_btn, start_btn, settings_btn, quit_btn]:
			btn.add_stylebox_override("normal", btn_style)
			btn.add_stylebox_override("hover", hover_style)
			btn.add_stylebox_override("pressed", pressed_style)
			btn.add_stylebox_override("focus", StyleBoxEmpty.new())
			# Ghi đè màu chữ để phù hợp với nền (có thể là nâu gỗ hoặc đen)
			btn.add_color_override("font_color", Color(0.9, 0.9, 0.9))
			
	# Ẩn các giao diện trong game bằng cách đẩy nó ra khỏi màn hình
	QuestUI.offset = Vector2(9999, 9999)
	JournalUI.offset = Vector2(9999, 9999)
	ChatUI.offset = Vector2(9999, 9999)

	_init_settings_panel()

var settings_panel: PanelContainer
var bgm_lbl: Label
var sfx_lbl: Label
var btn_mute_bgm: Button
var btn_mute_sfx: Button

func _init_settings_panel():
	var btn_font = DynamicFont.new()
	btn_font.font_data = load("res://assets/ARIAL.TTF")
	btn_font.size = 15
	
	var title_font = DynamicFont.new()
	title_font.font_data = load("res://assets/VT323-Regular.ttf")
	title_font.size = 32

	settings_panel = PanelContainer.new()
	settings_panel.rect_min_size = Vector2(460, 360)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.margin_left = -230
	settings_panel.margin_top = -180
	settings_panel.margin_right = 230
	settings_panel.margin_bottom = 180
	
	var panel_tex = load("res://assets/others/formal_dialog_panel_base_v1_1024x640.png")
	if panel_tex:
		var style = StyleBoxTexture.new()
		style.texture = panel_tex
		style.margin_left = 40
		style.margin_right = 40
		style.margin_top = 40
		style.margin_bottom = 40
		settings_panel.add_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 12)
	settings_panel.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "CÀI ĐẶT ÂM THANH"
	lbl_title.align = Label.ALIGN_CENTER
	lbl_title.add_font_override("font", title_font)
	lbl_title.add_color_override("font_color", Color(0.25, 0.15, 0.05))
	vbox.add_child(lbl_title)
	
	# BGM Slider
	bgm_lbl = Label.new()
	bgm_lbl.text = "Âm lượng Nhạc nền: %d%%" % int(AudioManager.bgm_volume * 100)
	bgm_lbl.add_font_override("font", btn_font)
	bgm_lbl.add_color_override("font_color", Color(0.2, 0.15, 0.1))
	vbox.add_child(bgm_lbl)
	
	var bgm_slider = HSlider.new()
	bgm_slider.min_value = 0
	bgm_slider.max_value = 100
	bgm_slider.step = 1
	bgm_slider.value = AudioManager.bgm_volume * 100
	bgm_slider.connect("value_changed", self, "_on_bgm_slider_changed")
	vbox.add_child(bgm_slider)
	
	# SFX Slider
	sfx_lbl = Label.new()
	sfx_lbl.text = "Âm lượng Hiệu ứng (SFX): %d%%" % int(AudioManager.sfx_volume * 100)
	sfx_lbl.add_font_override("font", btn_font)
	sfx_lbl.add_color_override("font_color", Color(0.2, 0.15, 0.1))
	vbox.add_child(sfx_lbl)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.value = AudioManager.sfx_volume * 100
	sfx_slider.connect("value_changed", self, "_on_sfx_slider_changed")
	vbox.add_child(sfx_slider)
	
	var hbox_toggles = HBoxContainer.new()
	hbox_toggles.add_constant_override("separation", 10)
	hbox_toggles.alignment = BoxContainer.ALIGN_CENTER
	vbox.add_child(hbox_toggles)
	
	btn_mute_bgm = Button.new()
	btn_mute_bgm.text = "Bật/Tắt Nhạc"
	btn_mute_bgm.rect_min_size = Vector2(140, 36)
	btn_mute_bgm.add_font_override("font", btn_font)
	UIUtils.style_button(btn_mute_bgm, Color(0.2, 0.45, 0.25))
	btn_mute_bgm.connect("pressed", self, "_on_toggle_bgm_pressed")
	hbox_toggles.add_child(btn_mute_bgm)
	
	btn_mute_sfx = Button.new()
	btn_mute_sfx.text = "Bật/Tắt SFX"
	btn_mute_sfx.rect_min_size = Vector2(140, 36)
	btn_mute_sfx.add_font_override("font", btn_font)
	UIUtils.style_button(btn_mute_sfx, Color(0.25, 0.35, 0.5))
	btn_mute_sfx.connect("pressed", self, "_on_toggle_sfx_pressed")
	hbox_toggles.add_child(btn_mute_sfx)
	
	var btn_close = Button.new()
	btn_close.text = "Đóng"
	btn_close.rect_min_size = Vector2(160, 38)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.add_font_override("font", btn_font)
	UIUtils.style_button(btn_close, Color(0.5, 0.2, 0.2))
	btn_close.connect("pressed", self, "_on_settings_close_pressed")
	vbox.add_child(btn_close)
	
	settings_panel.hide()
	add_child(settings_panel)

func _on_bgm_slider_changed(val: float):
	AudioManager.set_bgm_volume(val / 100.0)
	bgm_lbl.text = "Âm lượng Nhạc nền: %d%%" % int(val)

func _on_sfx_slider_changed(val: float):
	AudioManager.set_sfx_volume(val / 100.0)
	sfx_lbl.text = "Âm lượng Hiệu ứng (SFX): %d%%" % int(val)

func _on_toggle_bgm_pressed():
	AudioManager.toggle_bgm()
	if AudioManager.is_bgm_muted:
		btn_mute_bgm.text = "🔇 Đã tắt Nhạc"
	else:
		btn_mute_bgm.text = "🎵 Đang bật Nhạc"

func _on_toggle_sfx_pressed():
	AudioManager.toggle_sfx()
	if AudioManager.is_sfx_muted:
		btn_mute_sfx.text = "🔇 Đã tắt SFX"
	else:
		btn_mute_sfx.text = "🔊 Đang bật SFX"

func _on_settings_close_pressed():
	settings_panel.hide()

func _on_continue_pressed():
	QuestUI.offset = Vector2(0, 0)
	JournalUI.offset = Vector2(0, 0)
	ChatUI.offset = Vector2(0, 0)
	SaveManager.load_requested = true
	get_tree().change_scene("res://game/world/World.tscn")

func _on_start_pressed():
	# Xóa save cũ đi và reset
	SaveManager.delete_save()
	
	QuestUI.offset = Vector2(0, 0)
	JournalUI.offset = Vector2(0, 0)
	ChatUI.offset = Vector2(0, 0)
	
	# Reset singletons
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	TimeManager.day = 1
	TimeManager.week_day = 0
	TimeManager.calendar_events.clear()
	
	get_tree().change_scene("res://game/world/World.tscn")

func _on_settings_pressed():
	settings_panel.show()

func _on_quit_pressed():
	get_tree().quit()
