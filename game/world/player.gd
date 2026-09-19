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
	
	reset_cam_btn.hide()
	reset_cam_btn.connect("pressed", self, "_on_reset_cam_pressed")
	
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

func _physics_process(delta):
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
		
	# Logic bám đuổi của Camera
	if camera_mode == "FOLLOW":
		camera.global_position = camera.global_position.linear_interpolate(global_position, 10.0 * delta)
		
		# Xử lý ngoại lệ: Nếu người chơi đi vào Interior (tọa độ > 5000), mở khóa giới hạn Camera
		var bg_map = get_node_or_null("/root/World/BackgroundMap")
		if global_position.x > 5000 or global_position.y > 5000:
			# Tìm xem người chơi đang đứng trong phòng nào
			var interiors = get_node_or_null("/root/World/Interiors")
			var found_room = false
			if interiors != null:
				for room in interiors.get_children():
					var bg = room.get_node_or_null("Background")
					if bg != null and bg is Sprite and bg.texture != null:
						var tex_size = bg.texture.get_size()
						# Trừ hao hoặc cộng thêm vị trí phòng để ra HCN
						var rect = Rect2(room.global_position, tex_size)
						if rect.has_point(global_position):
							found_room = true
							camera.limit_left = int(rect.position.x)
							camera.limit_top = int(rect.position.y)
							camera.limit_right = int(rect.position.x + rect.size.x)
							camera.limit_bottom = int(rect.position.y + rect.size.y)
							
							# Tự động zoom cho vừa khít phòng (phóng to)
							var window_size = get_viewport_rect().size
							var zoom_x = rect.size.x / window_size.x
							var zoom_y = rect.size.y / window_size.y
							# Chọn mức zoom nhỏ hơn để ưu tiên lấp đầy màn hình, hoặc lớn hơn để thấy toàn bộ
							var target_zoom = max(zoom_x, zoom_y)
							# Zoom tối thiểu là 0.3 để không bị vỡ hạt quá mức
							target_zoom = max(target_zoom, 0.3)
							
							# Chuyển dần zoom cho mượt
							camera.zoom = camera.zoom.linear_interpolate(Vector2(target_zoom, target_zoom), 5.0 * delta)
							break
							
			if not found_room:
				# Nếu chưa tìm thấy phòng cụ thể, cứ mở toang limit
				camera.limit_left = -10000000
				camera.limit_top = -10000000
				camera.limit_right = 10000000
				camera.limit_bottom = 10000000
		else:
			# Đang ở ngoài đường, khóa theo map chính
			if bg_map != null and bg_map.texture != null:
				var tex_size = bg_map.texture.get_size()
				camera.limit_left = 0
				camera.limit_top = 0
				camera.limit_right = int(tex_size.x)
				camera.limit_bottom = int(tex_size.y)
			
			# Từ từ zoom lại mức cuộn chuột mong muốn khi bước ra ngoài
			camera.zoom = camera.zoom.linear_interpolate(desired_zoom, 5.0 * delta)

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

