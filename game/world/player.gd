extends KinematicBody2D

export var move_speed = 120.0
var velocity = Vector2.ZERO

onready var sprite = $Sprite
onready var camera = $Camera2D

var anim_timer = 0.0
var frame_index = 0
var current_dir = 0 # 0: Down, 1: Right, 2: Up, 3: Left

var is_panning = false
var camera_mode = "FOLLOW" # Hoặc "FREE"
onready var reset_cam_btn = $UICanvas/ResetCamBtn
var max_zoom = 5.0
var desired_zoom = Vector2(1.0, 1.0)

func _ready():
	# Cho phép Camera bay tự do khỏi Player
	camera.set_as_toplevel(true)
	camera.global_position = global_position
	
	# Khởi tạo Bảng theo dõi NPC trước để có sẵn font
	var f = File.new()
	f.open("res://asset_list.txt", File.WRITE)
	_scan_dir("res://assets", f)
	f.close()
	
	_init_npc_board()
	_init_god_mode_ui()
	_init_camera_zoom_ui()
	QuestUI.update_coins(coins)
	
	reset_cam_btn.hide()
	reset_cam_btn.connect("pressed", self, "_on_reset_cam_pressed")
	
	# Gán font tiếng Việt cho nút Về lại Nhân Vật
	reset_cam_btn.add_font_override("font", npc_board_font)
	UIUtils.style_button(reset_cam_btn)
	
	# Định vị lại nút Về lại Nhân Vật ra giữa màn hình phía trên cùng để không đè lên các menu God Mode
	reset_cam_btn.anchor_left = 0.5
	reset_cam_btn.anchor_right = 0.5
	reset_cam_btn.anchor_top = 0.0
	reset_cam_btn.anchor_bottom = 0.0
	reset_cam_btn.margin_left = -80
	reset_cam_btn.margin_right = 80
	reset_cam_btn.margin_top = 20
	reset_cam_btn.margin_bottom = 52
	
	# Thiết lập giới hạn màn hình bằng cách đọc kích thước map
	var bg_map = get_node_or_null("/root/World/BackgroundMap")
	if bg_map != null and bg_map is Sprite and bg_map.texture != null:
		var tex_size = bg_map.texture.get_size()
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(tex_size.x)
		camera.limit_bottom = int(tex_size.y)
		
		# Tính toán mức zoom lớn nhất không được vượt quá bản đồ (tối thiểu 3.0 để luôn zoom xa được)
		var window_size = get_viewport_rect().size
		var max_zoom_x = tex_size.x / window_size.x
		var max_zoom_y = tex_size.y / window_size.y
		max_zoom = max(min(max_zoom_x, max_zoom_y), 3.0)
		
	var mc = load("res://game/ui/mobile_controls.gd").new()
	add_child(mc)
	
	_init_guide_panel()
	_init_screen_fade()
	call_deferred("_init_save_state")

func _init_save_state():
	if SaveManager.has_save():
		SaveManager.apply_save_data()
	else:
		# Nếu là game mới (chưa có save), lưu ngay trạng thái ban đầu
		SaveManager.save_game()
		
func _scan_dir(path: String, f: File):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				_scan_dir(path + "/" + file_name, f)
			else:
				if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
					f.store_line(path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
	# Tìm tất cả các phòng nội thất bằng cách quét cây Scene
	_find_all_interior_backgrounds(get_tree().root)

var interior_backgrounds = []

func _find_all_interior_backgrounds(node: Node):
	if node.name == "BackgroundMap":
		return
		
	if node.name == "Background" and node is Sprite:
		interior_backgrounds.append(node)
		
	for child in node.get_children():
		_find_all_interior_backgrounds(child)

var npc_board_font: DynamicFont

var is_power_cut = false
var is_water_cut = false
var is_rent_high = false

var btn_electric: Button
var btn_water: Button
var btn_rent: Button

# Hệ thống kinh tế
var coins: int = 150

func add_coins(amount: int):
	coins += amount
	QuestUI.update_coins(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		QuestUI.update_coins(coins)
		return true
	return false

# Tui do (ten_vat_pham -> so_luong)
var inventory: Dictionary = {}

func add_item(item_name: String, count: int = 1):
	if item_name in inventory:
		inventory[item_name] += count
	else:
		inventory[item_name] = count
	QuestUI.refresh_inventory(inventory)

func remove_item(item_name: String, count: int = 1) -> bool:
	if inventory.get(item_name, 0) >= count:
		inventory[item_name] -= count
		if inventory[item_name] <= 0:
			inventory.erase(item_name)
		QuestUI.refresh_inventory(inventory)
		return true
	return false


func _init_npc_board():
	var ui_canvas = $UICanvas
	
	npc_board_font = DynamicFont.new()
	npc_board_font.font_data = load("res://assets/ARIAL.TTF")
	npc_board_font.size = 14
	
	var btn = Button.new()
	btn.text = "Lịch Trình NPC"
	btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn.rect_position = Vector2(130, -38)
	btn.rect_min_size = Vector2(130, 32)
	btn.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn)
	btn.connect("pressed", self, "_on_npc_board_toggle")
	ui_canvas.add_child(btn)
	
	var panel = PanelContainer.new()
	panel.name = "NPCBoard"
	panel.rect_position = Vector2(320, 170)
	panel.rect_size = Vector2(400, 370)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_stylebox_override("panel", style)
	
	panel.hide()
	ui_canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "--- HOẠT ĐỘNG CỦA CƯ DÂN ---"
	title.align = Label.ALIGN_CENTER
	title.add_font_override("font", npc_board_font)
	vbox.add_child(title)
	
	var event_label = Label.new()
	event_label.name = "EventLabel"
	event_label.text = "Sự kiện hiện tại: Bình thường"
	event_label.modulate = Color(1, 0.8, 0.2)
	event_label.align = Label.ALIGN_CENTER
	event_label.add_font_override("font", npc_board_font)
	vbox.add_child(event_label)
	
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.rect_min_size = Vector2(380, 260)
	vbox.add_child(scroll)
	
	var list = VBoxContainer.new()
	list.name = "List"
	list.size_flags_horizontal = 3
	scroll.add_child(list)
	
func _init_god_mode_ui():
	var ui_canvas = $UICanvas
	
	var god_mode_vbox = VBoxContainer.new()
	god_mode_vbox.rect_position = Vector2(20, 60)
	god_mode_vbox.add_constant_override("separation", 10)
	ui_canvas.add_child(god_mode_vbox)

	var weather_opt = OptionButton.new()
	weather_opt.name = "WeatherOption"
	weather_opt.rect_min_size = Vector2(160, 32)
	weather_opt.add_font_override("font", npc_board_font)
	weather_opt.add_item("Nắng ráo", 0)
	weather_opt.add_item("Mưa rào", 1)
	weather_opt.add_item("Bão tố", 2)
	weather_opt.add_item("Tuyết rơi", 3)
	weather_opt.add_item("Sương mù", 4)
	
	var current_idx = ["SUNNY", "RAIN", "STORM", "SNOW", "FOG"].find(TimeManager.current_weather)
	if current_idx != -1:
		weather_opt.selected = current_idx
		
	UIUtils.style_option_button(weather_opt)
	weather_opt.connect("item_selected", self, "_on_weather_selected")
	god_mode_vbox.add_child(weather_opt)

	# Nút bật/tắt bảng sự kiện
	var event_toggle_btn = Button.new()
	event_toggle_btn.text = "Sự Kiện Thị Trấn"
	event_toggle_btn.rect_min_size = Vector2(160, 32)
	event_toggle_btn.add_font_override("font", npc_board_font)
	UIUtils.style_button(event_toggle_btn, Color(0.22, 0.42, 0.28))
	event_toggle_btn.connect("pressed", self, "_on_event_panel_toggle")
	god_mode_vbox.add_child(event_toggle_btn)
	
	# Nhóm điều khiển cài đặt (nằm ở góc dưới cùng bên phải)
	var settings_vbox = VBoxContainer.new()
	settings_vbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	settings_vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	settings_vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	settings_vbox.margin_right = -20
	settings_vbox.margin_bottom = -20
	settings_vbox.add_constant_override("separation", 10)
	ui_canvas.add_child(settings_vbox)
	
	var audio_options = VBoxContainer.new()
	audio_options.name = "AudioOptions"
	audio_options.hide()
	settings_vbox.add_child(audio_options)
	
	var btn_bgm = Button.new()
	btn_bgm.name = "BtnBGM"
	btn_bgm.text = "🎵 Tắt Nhạc"
	btn_bgm.rect_min_size = Vector2(130, 32)
	btn_bgm.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_bgm)
	btn_bgm.connect("pressed", self, "_on_toggle_bgm")
	audio_options.add_child(btn_bgm)
	
	var btn_sfx = Button.new()
	btn_sfx.name = "BtnSFX"
	btn_sfx.text = "🔊 Tắt SFX"
	btn_sfx.rect_min_size = Vector2(130, 32)
	btn_sfx.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_sfx)
	btn_sfx.connect("pressed", self, "_on_toggle_sfx")
	audio_options.add_child(btn_sfx)
	
	var btn_save = Button.new()
	btn_save.name = "BtnSave"
	btn_save.text = "💾 Lưu Game"
	btn_save.rect_min_size = Vector2(130, 32)
	btn_save.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_save)
	btn_save.connect("pressed", self, "_on_save_game_pressed", [btn_save])
	audio_options.add_child(btn_save)
	
	var btn_guide = Button.new()
	btn_guide.name = "BtnGuide"
	btn_guide.text = "❓ Hướng Dẫn"
	btn_guide.rect_min_size = Vector2(130, 32)
	btn_guide.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_guide, Color(0.25, 0.42, 0.55))
	btn_guide.connect("pressed", self, "_on_guide_toggle")
	audio_options.add_child(btn_guide)
	
	var btn_main_menu = Button.new()
	btn_main_menu.name = "BtnMainMenu"
	btn_main_menu.text = "🏠 Menu Chính"
	btn_main_menu.rect_min_size = Vector2(130, 32)
	btn_main_menu.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_main_menu, Color(0.55, 0.25, 0.25))
	btn_main_menu.connect("pressed", self, "_on_return_main_menu")
	audio_options.add_child(btn_main_menu)
	
	var btn_settings = Button.new()
	btn_settings.text = "⚙️ Cài Đặt"
	btn_settings.rect_min_size = Vector2(130, 32)
	btn_settings.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_settings)
	btn_settings.connect("pressed", self, "_on_settings_toggle")
	settings_vbox.add_child(btn_settings)
	
	# Bảng Sự Kiện
	var event_panel = VBoxContainer.new()
	event_panel.name = "EventControls"
	event_panel.add_constant_override("separation", 4)
	event_panel.hide()
	god_mode_vbox.add_child(event_panel)

	btn_electric = Button.new()
	btn_electric.text = "⚡ Cắt Điện"
	btn_electric.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_electric, Color(0.8, 0.4, 0.2))
	btn_electric.connect("pressed", self, "_toggle_event", ["electric"])
	event_panel.add_child(btn_electric)
	
	btn_water = Button.new()
	btn_water.text = "💧 Cắt Nước"
	btn_water.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_water, Color(0.2, 0.5, 0.8))
	btn_water.connect("pressed", self, "_toggle_event", ["water"])
	event_panel.add_child(btn_water)
	
	btn_rent = Button.new()
	btn_rent.text = "💰 Tăng Giá Nhà"
	btn_rent.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_rent, Color(0.8, 0.6, 0.1))
	btn_rent.connect("pressed", self, "_toggle_event", ["rent"])
	event_panel.add_child(btn_rent)

var guide_panel: PanelContainer = null
var fade_rect: ColorRect = null
var fade_tween: Tween = null
var is_teleporting: bool = false

func _init_guide_panel():
	var ui_canvas = $UICanvas
	guide_panel = PanelContainer.new()
	guide_panel.name = "GuidePanel"
	guide_panel.rect_min_size = Vector2(520, 360)
	guide_panel.set_anchors_preset(Control.PRESET_CENTER)
	guide_panel.margin_left = -260
	guide_panel.margin_top = -180
	guide_panel.margin_right = 260
	guide_panel.margin_bottom = 180
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.96)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.72, 0.38)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	guide_panel.add_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 12)
	guide_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "📖 HƯỚNG DẪN CHƠI & ĐIỀU KHIỂN"
	title.align = Label.ALIGN_CENTER
	title.add_font_override("font", npc_board_font)
	title.add_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(title)
	
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.rect_min_size = Vector2(470, 240)
	rtl.add_font_override("normal_font", npc_board_font)
	rtl.bbcode_text = "[color=#88CCFF]• Di chuyển:[/color] Phím [color=#FFFF88]W, A, S, D[/color] hoặc Phím mũi tên (hoặc kéo Joystick ảo bên trái màn hình).\n" \
		+ "[color=#88CCFF]• Tương tác & Trò chuyện:[/color] Đứng gần NPC và nhấn phím [color=#FFFF88][E][/color] (hoặc nút tròn E trên màn hình).\n" \
		+ "[color=#88CCFF]• Camera (PC):[/color] Lăn chuột để Phóng to / Thu nhỏ; Giữ [color=#FFFF88]Chuột phải[/color] và kéo để quan sát toàn thị trấn.\n" \
		+ "[color=#88CCFF]• Camera (Điện thoại):[/color] Dùng 2 ngón tay chụm lại/mở ra hoặc bấm nút [color=#FFFF88][➕]/[➖][/color] để Zoom; Vuốt nửa phải màn hình để kéo xem toàn thị trấn (bấm nút [color=#FFFF88]Về Nhân Vật[/color] để quay lại).\n" \
		+ "[color=#88CCFF]• Phím tắt tiện ích:[/color] Nhấn [color=#FFFF88][Tab][/color] hoặc [color=#FFFF88][J][/color] mở Nhật ký; nhấn [color=#FFFF88][ESC][/color] mở nhanh Cài đặt / Tạm dừng.\n\n" \
		+ "[color=#FFAAFF]★ BÍ QUYẾT KHÁM PHÁ THỊ TRẤN:[/color]\n" \
		+ "1. Trò chuyện với cư dân để nhận [color=#AAFFAA]Nhiệm vụ[/color] kiếm Xu thưởng.\n" \
		+ "2. Dùng Xu mua Cà phê, Táo, Hoa tại Quán Cafe và Chợ.\n" \
		+ "3. Bấm [color=#FF88AA]🎁 Tặng Quà[/color] hoặc chăm chỉ hỏi thăm mỗi ngày để tăng [color=#FF4444]Trái Tim ♥[/color]. Khi đạt mốc 2♥ và 4♥, cư dân sẽ tiết lộ những bí mật động trời của thị trấn!"
	vbox.add_child(rtl)
	
	var btn_close = Button.new()
	btn_close.text = "Đã Hiểu (Đóng)"
	btn_close.rect_min_size = Vector2(160, 34)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.add_font_override("font", npc_board_font)
	UIUtils.style_button(btn_close, Color(0.25, 0.5, 0.3))
	btn_close.connect("pressed", self, "_on_guide_toggle")
	vbox.add_child(btn_close)
	
	guide_panel.hide()
	ui_canvas.add_child(guide_panel)

var is_holding_zoom_in = false
var is_holding_zoom_out = false

func _init_camera_zoom_ui():
	var ui_canvas = $UICanvas
	
	var zoom_controls = VBoxContainer.new()
	zoom_controls.name = "ZoomControls"
	zoom_controls.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	zoom_controls.margin_left = -62
	zoom_controls.margin_right = -14
	zoom_controls.margin_top = -54
	zoom_controls.margin_bottom = 54
	zoom_controls.add_constant_override("separation", 10)
	ui_canvas.add_child(zoom_controls)
	
	var btn_font = DynamicFont.new()
	btn_font.font_data = load("res://assets/ARIAL.TTF")
	btn_font.size = 20
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.14, 0.18, 0.68)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.85, 0.88, 0.95, 0.6)
	normal_style.corner_radius_top_left = 24
	normal_style.corner_radius_top_right = 24
	normal_style.corner_radius_bottom_left = 24
	normal_style.corner_radius_bottom_right = 24
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.25, 0.35, 0.5, 0.85)
	
	var btn_zoom_in = Button.new()
	btn_zoom_in.name = "BtnZoomIn"
	btn_zoom_in.text = "➕"
	btn_zoom_in.rect_min_size = Vector2(48, 48)
	btn_zoom_in.focus_mode = Control.FOCUS_NONE
	btn_zoom_in.add_font_override("font", btn_font)
	btn_zoom_in.add_stylebox_override("normal", normal_style)
	btn_zoom_in.add_stylebox_override("hover", normal_style)
	btn_zoom_in.add_stylebox_override("pressed", pressed_style)
	btn_zoom_in.add_stylebox_override("focus", StyleBoxEmpty.new())
	btn_zoom_in.connect("pressed", self, "_on_zoom_in_pressed")
	btn_zoom_in.connect("button_down", self, "_on_zoom_in_down")
	btn_zoom_in.connect("button_up", self, "_on_zoom_in_up")
	zoom_controls.add_child(btn_zoom_in)
	
	var btn_zoom_out = Button.new()
	btn_zoom_out.name = "BtnZoomOut"
	btn_zoom_out.text = "➖"
	btn_zoom_out.rect_min_size = Vector2(48, 48)
	btn_zoom_out.focus_mode = Control.FOCUS_NONE
	btn_zoom_out.add_font_override("font", btn_font)
	btn_zoom_out.add_stylebox_override("normal", normal_style)
	btn_zoom_out.add_stylebox_override("hover", normal_style)
	btn_zoom_out.add_stylebox_override("pressed", pressed_style)
	btn_zoom_out.add_stylebox_override("focus", StyleBoxEmpty.new())
	btn_zoom_out.connect("pressed", self, "_on_zoom_out_pressed")
	btn_zoom_out.connect("button_down", self, "_on_zoom_out_down")
	btn_zoom_out.connect("button_up", self, "_on_zoom_out_up")
	zoom_controls.add_child(btn_zoom_out)

func _on_zoom_in_pressed():
	desired_zoom -= Vector2(0.15, 0.15)
	desired_zoom.x = clamp(desired_zoom.x, 0.3, max_zoom)
	desired_zoom.y = clamp(desired_zoom.y, 0.3, max_zoom)

func _on_zoom_out_pressed():
	desired_zoom += Vector2(0.15, 0.15)
	desired_zoom.x = clamp(desired_zoom.x, 0.3, max_zoom)
	desired_zoom.y = clamp(desired_zoom.y, 0.3, max_zoom)

func _on_zoom_in_down():
	is_holding_zoom_in = true

func _on_zoom_in_up():
	is_holding_zoom_in = false

func _on_zoom_out_down():
	is_holding_zoom_out = true

func _on_zoom_out_up():
	is_holding_zoom_out = false

func _init_screen_fade():
	var fade_canvas = CanvasLayer.new()
	fade_canvas.name = "FadeCanvas"
	fade_canvas.layer = 100
	add_child(fade_canvas)
	
	fade_rect = ColorRect.new()
	fade_rect.name = "ScreenFade"
	fade_rect.set_anchors_preset(Control.PRESET_WIDE)
	fade_rect.color = Color(0, 0, 0, 1.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_canvas.add_child(fade_rect)
	
	fade_tween = Tween.new()
	add_child(fade_tween)
	
	# Chờ 1 nhịp khung hình để map và dữ liệu save khởi tạo xong dưới màn đen rồi mới mở màn mượt mà
	yield(get_tree(), "idle_frame")
	if is_instance_valid(fade_tween) and is_instance_valid(fade_rect):
		fade_tween.interpolate_property(fade_rect, "color:a", 1.0, 0.0, 0.55, Tween.TRANS_SINE, Tween.EASE_OUT)
		fade_tween.start()

func teleport_with_fade(target_pos: Vector2):
	if is_teleporting:
		return
	is_teleporting = true
	
	if fade_tween and fade_rect:
		fade_tween.stop_all()
		fade_tween.interpolate_property(fade_rect, "color:a", fade_rect.color.a, 1.0, 0.18, Tween.TRANS_SINE, Tween.EASE_IN)
		fade_tween.start()
		yield(fade_tween, "tween_completed")
		
	global_position = target_pos
	camera.global_position = target_pos
	
	if fade_tween and fade_rect:
		fade_tween.interpolate_property(fade_rect, "color:a", 1.0, 0.0, 0.25, Tween.TRANS_SINE, Tween.EASE_OUT)
		fade_tween.start()
		yield(fade_tween, "tween_completed")
		
	yield(get_tree().create_timer(0.15), "timeout")
	is_teleporting = false

func _on_guide_toggle():
	if guide_panel:
		guide_panel.visible = !guide_panel.visible

func _on_return_main_menu():
	# Tự động lưu tiến trình trước khi về Menu chính
	SaveManager.save_game()
	if ChatUI.panel.visible:
		ChatUI._on_close_pressed()
	if fade_tween and fade_rect:
		fade_tween.stop_all()
		fade_tween.interpolate_property(fade_rect, "color:a", fade_rect.color.a, 1.0, 0.25, Tween.TRANS_SINE, Tween.EASE_IN)
		fade_tween.start()
		yield(fade_tween, "tween_completed")
	get_tree().change_scene("res://game/ui/MainMenu.tscn")

func _on_weather_selected(idx: int):
	var weather_states = ["SUNNY", "RAIN", "STORM", "SNOW", "FOG"]
	TimeManager.change_weather(weather_states[idx])

func _on_toggle_bgm():
	AudioManager.toggle_bgm()
	var btn = $UICanvas.find_node("BtnBGM", true, false)
	if btn:
		btn.text = "🎵 Bật Nhạc" if AudioManager.is_bgm_muted else "🎵 Tắt Nhạc"

func _on_toggle_sfx():
	AudioManager.toggle_sfx()
	var btn = $UICanvas.find_node("BtnSFX", true, false)
	if btn:
		btn.text = "🔊 Bật SFX" if AudioManager.is_sfx_muted else "🔊 Tắt SFX"

func _on_save_game_pressed(btn: Button):
	SaveManager.save_game()
	if btn:
		btn.text = "Đã lưu!"
		yield(get_tree().create_timer(1.0), "timeout")
		if btn:
			btn.text = "💾 Lưu Game"

func _on_settings_toggle():
	var opts = $UICanvas.find_node("AudioOptions", true, false)
	if opts:
		opts.visible = !opts.visible

func _on_event_panel_toggle():
	var controls = $UICanvas.find_node("EventControls", true, false)
	if controls:
		controls.visible = !controls.visible

func _toggle_event(type: String):
	var desc = ""
	if type == "electric":
		is_power_cut = !is_power_cut
		btn_electric.text = "⚡ Cấp Điện Lại" if is_power_cut else "⚡ Cắt Điện"
		desc = "Toàn thị trấn vừa bị cúp điện đột ngột do bão." if is_power_cut else "Điện đã được khôi phục, đèn sáng trở lại."
	elif type == "water":
		is_water_cut = !is_water_cut
		btn_water.text = "💧 Cấp Nước Lại" if is_water_cut else "💧 Cắt Nước"
		desc = "Đường ống nước bị vỡ, toàn thị trấn mất nước." if is_water_cut else "Đường ống nước đã sửa xong, có nước lại."
	elif type == "rent":
		is_rent_high = !is_rent_high
		btn_rent.text = "💰 Giảm Giá Nhà" if is_rent_high else "💰 Tăng Giá Nhà"
		desc = "Thị trưởng tuyên bố tăng giá thuê nhà gấp đôi." if is_rent_high else "Thị trưởng đã giảm giá nhà về mức bình thường."
		
	WorldLog.current_world_event = desc
	WorldLog.add_entry("THÔNG BÁO KHẨN: " + desc)
	
	var npcs = get_tree().get_nodes_in_group("npcs")
	for n in npcs:
		if n.has_method("_on_world_event_received"):
			n._on_world_event_received(desc)
	update_npc_board()

func _on_npc_board_toggle():
	var board = $UICanvas/NPCBoard
	var controls = $UICanvas.find_node("EventControls", true, false)
	board.visible = !board.visible
	if controls:
		controls.visible = board.visible
	if board.visible:
		update_npc_board()

func update_npc_board():
	var event_lbl = $UICanvas/NPCBoard/VBox/EventLabel
	if event_lbl:
		event_lbl.text = "Sự kiện hiện tại: " + WorldLog.current_world_event
		
	var list = $UICanvas/NPCBoard/VBox/ScrollContainer/List
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
		
	var npcs = get_tree().get_nodes_in_group("npcs")
	print("Updating NPC Board, found NPCs: ", npcs.size())
	
	var dummy = Label.new()
	dummy.add_font_override("font", npc_board_font)
	dummy.text = "Tổng số NPC tìm thấy: " + str(npcs.size())
	dummy.modulate = Color(0, 1, 0) # Màu xanh lá cây
	list.add_child(dummy)
	
	for n in npcs:
		var lbl = Label.new()
		lbl.add_font_override("font", npc_board_font)
		lbl.rect_min_size = Vector2(360, 0)
		
		var action = "Đang rảnh rỗi"
		if n.npc_memory["history_logs"].size() > 0:
			action = n.npc_memory["history_logs"].back()
			
		var state_str = "Bình thường"
		match n.current_state:
			0: state_str = "Đang đứng chơi" # IDLE
			1: state_str = "Đang đi bộ" # WALKING
			2: state_str = "Đang trò chuyện" # TALKING
			3: state_str = "Đang đợi bạn" # WAITING_FOR_PLAYER
			4: state_str = "Đang khóc lóc 😭" # CRYING
			
		var loc_str = "Ngoài đường"
		for bg in interior_backgrounds:
			if is_instance_valid(bg) and bg.texture != null:
				var rect = Rect2(bg.global_position, bg.texture.get_size())
				if rect.has_point(n.global_position):
					loc_str = bg.get_parent().name
					break
			
		lbl.text = "👤 " + n.npc_name + " (" + loc_str + " | " + state_str + "):\n   └ " + action
		lbl.autowrap = true
		list.add_child(lbl)
		
		var space = Control.new()
		space.rect_min_size = Vector2(0, 10)
		list.add_child(space)

func _physics_process(delta):
	if is_holding_zoom_in:
		desired_zoom -= Vector2(0.6, 0.6) * delta
		desired_zoom.x = clamp(desired_zoom.x, 0.3, max_zoom)
		desired_zoom.y = clamp(desired_zoom.y, 0.3, max_zoom)
	elif is_holding_zoom_out:
		desired_zoom += Vector2(0.6, 0.6) * delta
		desired_zoom.x = clamp(desired_zoom.x, 0.3, max_zoom)
		desired_zoom.y = clamp(desired_zoom.y, 0.3, max_zoom)

	if Engine.get_frames_drawn() % 60 == 0:
		var board = $UICanvas.get_node_or_null("NPCBoard")
		if board and board.visible:
			update_npc_board()
			
	# ... Logic di chuyển cũ giữ nguyên
	if ChatUI.panel.visible:
		velocity = Vector2.ZERO
		AudioManager.stop_footstep()
		update_animation(delta)
	else:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		input_vector = input_vector.normalized()
		
		velocity = input_vector * move_speed
		velocity = move_and_slide(velocity)
		# Play footstep sound when moving
		if velocity.length() > 0:
			AudioManager.play_footstep()
		else:
			AudioManager.stop_footstep()
		
		update_animation(delta)
		
	var target_zoom_vec = desired_zoom
	
	var found_room_rect = Rect2()
	var in_room = false
	var active_bg = null
	
	for bg in interior_backgrounds:
		if is_instance_valid(bg) and bg.texture != null:
			var tex_size = bg.texture.get_size()
			# Vì background của phòng có centered = false, toạ độ của nó là góc trên trái
			var rect = Rect2(bg.global_position, tex_size)
			if rect.has_point(global_position):
				found_room_rect = rect
				in_room = true
				active_bg = bg
				break
				
	_update_room_visibility(active_bg)
	
	if in_room:
		var window_size = get_viewport_rect().size
		var zoom_x = found_room_rect.size.x / window_size.x
		var zoom_y = found_room_rect.size.y / window_size.y
		var tz = max(zoom_x, zoom_y)
		tz = max(tz, 0.3)
		
		# Kích thước thực tế của camera khi đã zoom
		var cam_w = window_size.x * tz
		var cam_h = window_size.y * tz
		
		var limit_l = found_room_rect.position.x
		var limit_r = found_room_rect.position.x + found_room_rect.size.x
		var limit_t = found_room_rect.position.y
		var limit_b = found_room_rect.position.y + found_room_rect.size.y
		
		# Khắc phục lỗi lệch phải/dưới: Nếu giới hạn hẹp hơn camera thì nới rộng đều 2 bên để đưa phòng vào chính giữa
		if (limit_r - limit_l) < cam_w:
			var diff = cam_w - (limit_r - limit_l)
			limit_l -= diff / 2.0
			limit_r += diff / 2.0
			
		if (limit_b - limit_t) < cam_h:
			var diff = cam_h - (limit_b - limit_t)
			limit_t -= diff / 2.0
			limit_b += diff / 2.0
			
		if camera_mode == "FOLLOW":
			camera.limit_left = int(limit_l)
			camera.limit_top = int(limit_t)
			camera.limit_right = int(limit_r)
			camera.limit_bottom = int(limit_b)
			target_zoom_vec = desired_zoom
				

	else:
		var bg_map = get_node_or_null("/root/World/BackgroundMap")
		if bg_map != null and bg_map.texture != null:
			var tex_size = bg_map.texture.get_size()
			var town_rect = Rect2(0, 0, tex_size.x, tex_size.y)
			
			if town_rect.has_point(global_position):
				if camera_mode == "FOLLOW":
					camera.limit_left = 0
					camera.limit_top = 0
					camera.limit_right = int(tex_size.x)
					camera.limit_bottom = int(tex_size.y)
			else:
				# Nằm ngoài cả town map và không thuộc phòng nào (vùng tự do)
				if camera_mode == "FOLLOW":
					camera.limit_left = -10000000
					camera.limit_top = -10000000
					camera.limit_right = 10000000
					camera.limit_bottom = 10000000
			
	# Luôn luôn áp dụng mượt zoom dù ở chế độ nào (lerp nhanh hơn để không bị khựng)
	camera.zoom = camera.zoom.linear_interpolate(target_zoom_vec, 12.0 * delta)
	
	# Xử lý nội suy di chuyển Camera
	if camera_mode == "FOLLOW":
		camera.global_position = camera.global_position.linear_interpolate(global_position, 12.0 * delta)

# Hàm xử lý thay đổi frame của sprite sheet
func update_animation(delta):
	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0: current_dir = 1
			else: current_dir = 3
		else:
			if velocity.y > 0: current_dir = 0
			else: current_dir = 2
			
		anim_timer += delta
		if anim_timer >= 0.15:
			anim_timer = 0.0
			frame_index = (frame_index + 1) % 4
	else:
		frame_index = 0
		
	sprite.frame = current_dir * 4 + frame_index

func _is_mouse_over_scroll_ui() -> bool:
	var m_pos = get_viewport().get_mouse_position()
	if ChatUI.panel.visible and ChatUI.panel.get_global_rect().has_point(m_pos):
		return true
	var qp = QuestUI.get_node_or_null("QuestPanel")
	if qp and qp.visible and qp.get_global_rect().has_point(m_pos):
		return true
	var ip = QuestUI.get_node_or_null("InvPanel")
	if ip and ip.visible and ip.get_global_rect().has_point(m_pos):
		return true
	var jp = JournalUI.get_node_or_null("Panel")
	if jp and jp.visible and jp.get_global_rect().has_point(m_pos):
		return true
	var nb = $UICanvas.get_node_or_null("NPCBoard")
	if nb and nb.visible and nb.get_global_rect().has_point(m_pos):
		return true
	if guide_panel and guide_panel.visible and guide_panel.get_global_rect().has_point(m_pos):
		return true
	return false

var touch_points = {}
var prev_pinch_dist = -1.0
var prev_pinch_center = Vector2.ZERO
var is_touch_panning = false

func _is_pos_over_ui(pos: Vector2) -> bool:
	if _is_mouse_over_scroll_ui():
		return true
	if reset_cam_btn and reset_cam_btn.visible and reset_cam_btn.get_global_rect().has_point(pos):
		return true
	var zc = $UICanvas.get_node_or_null("ZoomControls")
	if zc and zc.visible and zc.get_global_rect().has_point(pos):
		return true
	var vp = get_viewport_rect().size
	# Vùng nút Cài đặt ở góc dưới phải
	if pos.x > (vp.x - 160) and pos.y > (vp.y - 70):
		return true
	# Vùng nút tương tác E
	if pos.x > (vp.x - 265) and pos.x < (vp.x - 150) and pos.y > (vp.y - 135) and pos.y < (vp.y - 30):
		return true
	# Vùng nút góc dưới trái (Nhật ký, Lịch trình NPC)
	if pos.y > (vp.y - 50) and pos.x < 280:
		return true
	return false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_ESCAPE:
			if ChatUI.panel.visible:
				ChatUI._on_close_pressed()
			elif guide_panel and guide_panel.visible:
				guide_panel.hide()
			else:
				_on_settings_toggle()
			return
			
	if event is InputEventMouseButton:
		# Zoom to nhỏ mượt mà, chỉ nhận khi event.pressed == true để không bị kích hoạt 2 lần
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
				# Nếu chuột đang nằm trong các bảng danh sách cuộn thì để cho bảng đó cuộn
				if not _is_mouse_over_scroll_ui():
					if event.button_index == BUTTON_WHEEL_UP:
						desired_zoom -= Vector2(0.1, 0.1)
					elif event.button_index == BUTTON_WHEEL_DOWN:
						desired_zoom += Vector2(0.1, 0.1)
					
					desired_zoom.x = clamp(desired_zoom.x, 0.3, max_zoom)
					desired_zoom.y = clamp(desired_zoom.y, 0.3, max_zoom)
			
		# Nhấn giữ Chuột Phải hoặc Chuột Giữa để di chuyển Camera
		if event.button_index == BUTTON_RIGHT or event.button_index == BUTTON_MIDDLE:
			is_panning = event.pressed
			
	if event is InputEventMouseMotion and is_panning:
		# Bật chế độ camera tự do
		camera_mode = "FREE"
		reset_cam_btn.show()
		
		# Dịch chuyển Camera theo độ vẩy chuột (nhân với độ zoom để trượt mượt mà)
		camera.global_position -= event.relative * camera.zoom

	# Xử lý cảm ứng chạm trên điện thoại (Touch Events)
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _is_pos_over_ui(event.position):
				touch_points[event.index] = event.position
				if touch_points.size() == 2:
					var pts = touch_points.values()
					prev_pinch_dist = pts[0].distance_to(pts[1])
					prev_pinch_center = (pts[0] + pts[1]) * 0.5
					is_touch_panning = false
				elif touch_points.size() == 1:
					var screen_w = get_viewport_rect().size.x
					# Chỉ kéo map 1 ngón tay khi chạm ở nửa phải màn hình (tránh đè lên joystick di chuyển)
					if event.position.x > (screen_w * 0.45):
						is_touch_panning = true
					else:
						is_touch_panning = false
		else:
			touch_points.erase(event.index)
			if touch_points.size() < 2:
				prev_pinch_dist = -1.0
			if touch_points.empty():
				is_touch_panning = false

	if event is InputEventScreenDrag:
		if touch_points.has(event.index):
			touch_points[event.index] = event.position
			
		# Chạm 2 ngón tay: Chụm/mở để Zoom và cùng kéo để dời Camera
		if touch_points.size() >= 2:
			var pts = touch_points.values()
			var cur_dist = pts[0].distance_to(pts[1])
			var cur_center = (pts[0] + pts[1]) * 0.5
			
			if prev_pinch_dist > 0.0:
				var dist_delta = cur_dist - prev_pinch_dist
				if abs(dist_delta) > 1.5:
					var zoom_delta = dist_delta * 0.005 * camera.zoom.x
					desired_zoom -= Vector2(zoom_delta, zoom_delta)
					desired_zoom.x = clamp(desired_zoom.x, 0.3, max_zoom)
					desired_zoom.y = clamp(desired_zoom.y, 0.3, max_zoom)
				
				var center_delta = cur_center - prev_pinch_center
				if center_delta.length() > 1.5:
					camera_mode = "FREE"
					reset_cam_btn.show()
					camera.global_position -= center_delta * camera.zoom
			
			prev_pinch_dist = cur_dist
			prev_pinch_center = cur_center
			
		# Chạm 1 ngón tay ở nửa phải màn hình: Kéo xem bản đồ
		elif touch_points.size() == 1 and is_touch_panning:
			camera_mode = "FREE"
			reset_cam_btn.show()
			camera.global_position -= event.relative * camera.zoom

func _on_reset_cam_pressed():
	camera_mode = "FOLLOW"
	reset_cam_btn.hide()

var current_active_bg = null

func _update_room_visibility(active_bg: Node):
	if active_bg == current_active_bg:
		return
	current_active_bg = active_bg
	
	var in_room = (active_bg != null)
	if in_room and active_bg is Sprite and active_bg.texture != null:
		var window_size = get_viewport_rect().size
		var tex_size = active_bg.texture.get_size()
		var tz = max(tex_size.x / window_size.x, tex_size.y / window_size.y)
		tz = max(tz, 0.4)
		desired_zoom = Vector2(tz, tz)
	
	for bg in interior_backgrounds:
		if is_instance_valid(bg):
			var room_node = bg.get_parent()
			var is_active = (bg == active_bg)
			
			bg.visible = is_active
			var ysort = room_node.get_node_or_null("YSort")
			if ysort != null:
				ysort.visible = is_active
				
	# Ẩn/hiện toàn bộ Town Map khi vào/ra phòng nội thất
	var bg_map = get_node_or_null("/root/World/BackgroundMap")
	var tile_map = get_node_or_null("/root/World/CollisionMap")
	var labels = get_node_or_null("/root/World/HouseLabels")
	var doors = get_node_or_null("/root/World/Doors") # Ẩn các cánh cửa trên map ngoài
	var obstacles = get_node_or_null("/root/World/ObstaclePoly3") # Có thể ẩn các chướng ngại vật ngoài map
	
	if bg_map != null: bg_map.visible = !in_room
	if tile_map != null: tile_map.visible = !in_room
	if labels != null: labels.visible = !in_room
	if doors != null: doors.visible = !in_room
	if obstacles != null: obstacles.visible = !in_room





