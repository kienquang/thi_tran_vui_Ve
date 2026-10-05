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
		
		# Tính toán mức zoom lớn nhất không được vượt quá bản đồ
		var window_size = get_viewport_rect().size
		var max_zoom_x = tex_size.x / window_size.x
		var max_zoom_y = tex_size.y / window_size.y
		max_zoom = min(max_zoom_x, max_zoom_y)
		
	if SaveManager.load_requested:
		SaveManager.apply_save_data()
	else:
		# Nếu là game mới, lưu ngay trạng thái ban đầu
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
	btn.text = "Lich Trinh NPC"
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
	event_toggle_btn.text = "Su Kien Thi Tran"
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
	btn_save.connect("pressed", SaveManager, "save_game")
	audio_options.add_child(btn_save)
	
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
			target_zoom_vec = Vector2(tz, tz)
				

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
			
	# Luôn luôn áp dụng mượt zoom dù ở chế độ nào
	camera.zoom = camera.zoom.linear_interpolate(target_zoom_vec, 5.0 * delta)
	
	# Xử lý nội suy di chuyển Camera
	if camera_mode == "FOLLOW":
		camera.global_position = camera.global_position.linear_interpolate(global_position, 10.0 * delta)

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

func _unhandled_input(event):
	if event is InputEventMouseButton:
		# Zoom to nhỏ
		if event.button_index == BUTTON_WHEEL_UP:
			desired_zoom -= Vector2(0.2, 0.2)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			desired_zoom += Vector2(0.2, 0.2)
			
		# Nới lỏng giới hạn zoom lên mức tối đa vừa khít bản đồ
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

func _on_reset_cam_pressed():
	camera_mode = "FOLLOW"
	reset_cam_btn.hide()

var current_active_bg = null

func _update_room_visibility(active_bg: Node):
	if active_bg == current_active_bg:
		return
	current_active_bg = active_bg
	
	var in_room = (active_bg != null)
	
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





