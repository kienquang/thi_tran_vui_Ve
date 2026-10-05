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
	# Hiển thị UI Cài đặt (ví dụ bật/tắt âm thanh)
	print("Settings clicked")

func _on_quit_pressed():
	get_tree().quit()
