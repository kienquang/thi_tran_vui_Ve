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
	_init_npc_board()
	
	reset_cam_btn.hide()
	reset_cam_btn.connect("pressed", self, "_on_reset_cam_pressed")
	
	# Gán font tiếng Việt cho nút Về lại Nhân Vật
	reset_cam_btn.add_font_override("font", npc_board_font)
	
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

func _init_npc_board():
	var ui_canvas = $UICanvas
	
	npc_board_font = DynamicFont.new()
	npc_board_font.font_data = load("res://assets/ARIAL.TTF")
	npc_board_font.size = 14
	
	var btn = Button.new()
	btn.text = "📍 Xem Lịch Trình NPC"
	btn.rect_position = Vector2(20, 140)
	btn.add_font_override("font", npc_board_font)
	btn.connect("pressed", self, "_on_npc_board_toggle")
	ui_canvas.add_child(btn)
	
	var panel = PanelContainer.new()
	panel.name = "NPCBoard"
	panel.rect_position = Vector2(20, 180)
	panel.rect_size = Vector2(400, 360)
	
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
	
	# --- Cụm nút tạo sự kiện (God Mode) ---
	var event_panel = HBoxContainer.new()
	event_panel.name = "EventControls"
	event_panel.rect_position = Vector2(440, 180)
	event_panel.hide()
	ui_canvas.add_child(event_panel)
	
	btn_electric = Button.new()
	btn_electric.text = "⚡ Cắt Điện"
	btn_electric.add_font_override("font", npc_board_font)
	btn_electric.connect("pressed", self, "_toggle_event", ["electric"])
	event_panel.add_child(btn_electric)
	
	btn_water = Button.new()
	btn_water.text = "💧 Cắt Nước"
	btn_water.add_font_override("font", npc_board_font)
	btn_water.connect("pressed", self, "_toggle_event", ["water"])
	event_panel.add_child(btn_water)
	
	btn_rent = Button.new()
	btn_rent.text = "💰 Tăng Giá Nhà"
	btn_rent.add_font_override("font", npc_board_font)
	btn_rent.connect("pressed", self, "_toggle_event", ["rent"])
	event_panel.add_child(btn_rent)

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
	var controls = $UICanvas/EventControls
	board.visible = !board.visible
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
		update_animation(delta)
	else:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		input_vector = input_vector.normalized()
		
		velocity = input_vector * move_speed
		velocity = move_and_slide(velocity)
		
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

