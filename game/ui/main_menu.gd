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
	
	var guide_btn = Button.new()
	guide_btn.name = "GuideButton"
	guide_btn.text = "Hướng dẫn"
	guide_btn.rect_min_size = Vector2(250, 44)
	guide_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$CenterContainer/Panel/VBoxContainer.add_child(guide_btn)
	$CenterContainer/Panel/VBoxContainer.move_child(guide_btn, quit_btn.get_index())
	
	continue_btn.add_font_override("font", btn_font)
	start_btn.add_font_override("font", btn_font)
	settings_btn.add_font_override("font", btn_font)
	guide_btn.add_font_override("font", btn_font)
	quit_btn.add_font_override("font", btn_font)
	
	continue_btn.connect("pressed", self, "_on_continue_pressed")
	start_btn.connect("pressed", self, "_on_start_pressed")
	settings_btn.connect("pressed", self, "_on_settings_pressed")
	guide_btn.connect("pressed", self, "_on_guide_pressed")
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
		
		for btn in [continue_btn, start_btn, settings_btn, guide_btn, quit_btn]:
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
	_init_guide_panel()
	_init_menu_fade()

var settings_panel: PanelContainer
var guide_panel: PanelContainer
var bgm_lbl: Label
var sfx_lbl: Label
var btn_mute_bgm: Button
var btn_mute_sfx: Button
var menu_fade: ColorRect
var menu_tween: Tween
var is_transitioning: bool = false

func _init_menu_fade():
	menu_fade = ColorRect.new()
	menu_fade.name = "MenuFade"
	menu_fade.set_anchors_preset(Control.PRESET_WIDE)
	menu_fade.color = Color(0, 0, 0, 1.0)
	menu_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_fade)
	
	menu_tween = Tween.new()
	add_child(menu_tween)
	menu_tween.interpolate_property(menu_fade, "color:a", 1.0, 0.0, 0.45, Tween.TRANS_SINE, Tween.EASE_OUT)
	menu_tween.start()

func _init_settings_panel():
	var btn_font = DynamicFont.new()
	btn_font.font_data = load("res://assets/ARIAL.TTF")
	btn_font.size = 15
	
	var title_font = DynamicFont.new()
	title_font.font_data = load("res://assets/VT323-Regular.ttf")
	title_font.size = 32

	settings_panel = PanelContainer.new()
	settings_panel.rect_min_size = Vector2(540, 420)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.margin_left = -270
	settings_panel.margin_top = -210
	settings_panel.margin_right = 270
	settings_panel.margin_bottom = 210
	
	var panel_tex = load("res://assets/others/formal_dialog_panel_base_v1_1024x640.png")
	if panel_tex:
		var style = StyleBoxTexture.new()
		style.texture = panel_tex
		style.margin_left = 45
		style.margin_right = 45
		style.margin_top = 40
		style.margin_bottom = 40
		style.content_margin_left = 80
		style.content_margin_right = 80
		style.content_margin_top = 78
		style.content_margin_bottom = 64
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

func _init_guide_panel():
	var btn_font = DynamicFont.new()
	btn_font.font_data = load("res://assets/ARIAL.TTF")
	btn_font.size = 15
	
	var title_font = DynamicFont.new()
	title_font.font_data = load("res://assets/ARIAL.TTF")
	title_font.size = 20

	guide_panel = PanelContainer.new()
	guide_panel.rect_min_size = Vector2(660, 470)
	guide_panel.set_anchors_preset(Control.PRESET_CENTER)
	guide_panel.margin_left = -330
	guide_panel.margin_top = -235
	guide_panel.margin_right = 330
	guide_panel.margin_bottom = 235
	
	var panel_tex = load("res://assets/others/formal_dialog_panel_base_v1_1024x640.png")
	if panel_tex:
		var style = StyleBoxTexture.new()
		style.texture = panel_tex
		style.margin_left = 45
		style.margin_right = 45
		style.margin_top = 40
		style.margin_bottom = 40
		style.content_margin_left = 86
		style.content_margin_right = 86
		style.content_margin_top = 86
		style.content_margin_bottom = 68
		guide_panel.add_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 8)
	guide_panel.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "HƯỚNG DẪN CHƠI & ĐIỀU KHIỂN"
	lbl_title.align = Label.ALIGN_CENTER
	lbl_title.add_font_override("font", title_font)
	lbl_title.add_color_override("font_color", Color(0.25, 0.15, 0.05))
	vbox.add_child(lbl_title)
	
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.rect_min_size = Vector2(480, 225)
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rtl.add_font_override("normal_font", btn_font)
	rtl.add_color_override("default_color", Color(0.2, 0.12, 0.05))
	rtl.bbcode_text = "• [color=#8B0000]Di chuyển:[/color] Phím W, A, S, D hoặc Phím mũi tên (hoặc kéo Joystick ảo trên màn hình).\n" \
		+ "• [color=#8B0000]Tương tác & Trò chuyện:[/color] Đứng gần cư dân và nhấn phím [E] (hoặc nút tròn E).\n" \
		+ "• [color=#8B0000]Camera (PC):[/color] Lăn chuột để Phóng to / Thu nhỏ; Giữ Chuột phải kéo để xem bản đồ.\n" \
		+ "• [color=#8B0000]Camera (Mobile):[/color] Dùng 2 ngón tay chụm lại/mở ra hoặc bấm nút [➕]/[➖] để Zoom; Vuốt nửa phải màn hình để kéo xem bản đồ (bấm nút [Về Nhân Vật] để quay lại).\n" \
		+ "• [color=#8B0000]Phím tắt tiện ích:[/color] Nhấn [Tab] hoặc [J] mở Nhật ký; nhấn [ESC] mở nhanh Cài đặt.\n\n" \
		+ "[color=#004d00]★ CẨM NANG KHÁM PHÁ THỊ TRẤN:[/color]\n" \
		+ "1. Nhận nhiệm vụ từ các cư dân để kiếm Xu thưởng.\n" \
		+ "2. Dùng Xu mua Cà phê, Trái táo, Hoa tại Quán Cafe và Chợ.\n" \
		+ "3. Tặng quà (🎁) hoặc trò chuyện mỗi ngày để tăng Trái Tim (♥). Khi đạt 2♥ và 4♥, cư dân sẽ bật mí những bí mật động trời của thị trấn!"
	vbox.add_child(rtl)
	
	var btn_close = Button.new()
	btn_close.text = "Đã Hiểu (Đóng)"
	btn_close.rect_min_size = Vector2(160, 36)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.add_font_override("font", btn_font)
	UIUtils.style_button(btn_close, Color(0.25, 0.48, 0.28))
	btn_close.connect("pressed", self, "_on_guide_close_pressed")
	vbox.add_child(btn_close)
	
	guide_panel.hide()
	add_child(guide_panel)

func _on_settings_close_pressed():
	settings_panel.hide()

func _on_guide_pressed():
	settings_panel.hide()
	guide_panel.show()

func _on_guide_close_pressed():
	guide_panel.hide()

func _fade_and_enter_world():
	if menu_tween and menu_fade:
		menu_fade.mouse_filter = Control.MOUSE_FILTER_STOP
		menu_tween.stop_all()
		menu_tween.interpolate_property(menu_fade, "color:a", menu_fade.color.a, 1.0, 0.45, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		menu_tween.start()
		yield(menu_tween, "tween_completed")
	QuestUI.offset = Vector2(0, 0)
	JournalUI.offset = Vector2(0, 0)
	ChatUI.offset = Vector2(0, 0)
	get_tree().change_scene("res://game/world/World.tscn")

func _on_continue_pressed():
	if is_transitioning:
		return
	is_transitioning = true
	SaveManager.load_requested = true
	_fade_and_enter_world()

func _on_start_pressed():
	if is_transitioning:
		return
	is_transitioning = true
	# Xóa save cũ đi và reset
	SaveManager.delete_save()
	
	# Reset singletons
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	TimeManager.day = 1
	TimeManager.week_day = 0
	TimeManager.calendar_events.clear()
	
	_fade_and_enter_world()

func _on_settings_pressed():
	guide_panel.hide()
	settings_panel.show()

func _on_quit_pressed():
	get_tree().quit()
