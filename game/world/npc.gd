extends KinematicBody2D

export(Texture) var npc_sprite
export var npc_name = "Thị Trưởng"
export var npc_personality = "Thân thiện, nhiệt tình và luôn quan tâm đến mọi người."
export var schedule = {
	8: "park_center",
	12: "cafe_entrance",
	18: "mayor_house"
}

var npc_memory = {
	"name": "",
	"personality": "",
	"relationships": {},
	"history_logs": []
}

enum State { IDLE, WALKING, TALKING, WAITING_FOR_PLAYER, CRYING }
var current_state = State.IDLE

var move_speed = 80.0
var target_position = Vector2.ZERO
var base_wander_position = Vector2.ZERO

var final_destination = Vector2.ZERO
var entrance_door_pos = Vector2.ZERO

var velocity = Vector2.ZERO

onready var sprite = $Sprite
onready var llm_client = $LLMClient
onready var speech_bubble = $SpeechBubble
onready var prompt_label = $PromptLabel
onready var detection_zone = $DetectionZone

var anim_timer = 0.0
var frame_index = 0
var current_dir = 0
var current_schedule_hour = -1

var player_near = false
var player_node = null
var nearby_npcs = []
var npc_cooldown = 0.0
var chat_partner = null

func _ready():
	add_to_group("npcs")
	randomize()
	
	# Bỏ qua va chạm vật lý với các NPC khác để không bị đẩy/kẹt nhau
	call_deferred("_disable_npc_collisions")
			
	# Cấu hình Lịch trình và Tính cách chi tiết cho 9 nhân vật

	if npc_name == "Thị Trưởng":
		npc_name = "Thị trưởng Thomas"
		npc_personality = "Thị trưởng của thị trấn. Luôn tự hào về công trình công cộng, thích đi kiểm tra."
		schedule = { 6: "home_b", 8: "town_hall", 12: "dining_hall", 14: "park_center", 18: "home_b" }
	elif npc_name == "Cô Gái":
		npc_name = "Alice"
		npc_personality = "Một cô gái trẻ mơ mộng, yêu đọc sách và thích ngắm cảnh ở bến tàu. Vợ của Bác sĩ John."
		schedule = { 6: "home_a", 9: "library", 13: "cafe_entrance", 16: "dock", 20: "home_a" }
	elif npc_name == "Cư dân 1":
		npc_name = "Bác sĩ John"
		npc_personality = "Bác sĩ tận tâm của trạm xá, luôn lo lắng cho sức khỏe mọi người. Chồng của Alice."
		schedule = { 6: "home_a", 8: "clinic", 12: "cafe_entrance", 14: "clinic", 19: "home_a" }
	elif npc_name == "Cư dân 2":
		npc_name = "Thợ mộc Bob"
		npc_personality = "Thợ mộc yêu nghề, cả ngày cặm cụi ở xưởng. Chồng của Thủ thư Mary."
		schedule = { 6: "home_c", 8: "workshop", 12: "dining_hall", 13: "workshop", 19: "home_c" }
	elif npc_name == "Cư dân 3":
		npc_name = "Thủ thư Mary"
		npc_personality = "Người quản lý thư viện trầm tính, rất thích những cuốn sách cổ. Vợ của Thợ mộc Bob."
		schedule = { 6: "home_c", 8: "library", 17: "park_center", 19: "home_c" }
	elif npc_name == "Cư dân 4":
		npc_name = "Tiểu thương Anna"
		npc_personality = "Chủ tiệm tạp hóa ở khu chợ, lanh lẹ và luôn chào mời khách mua hàng. Sống độc thân."
		schedule = { 6: "home_d", 8: "market", 13: "cafe_entrance", 15: "market", 20: "home_d" }
	elif npc_name == "Cư dân 5":
		npc_name = "Thủy thủ Jack"
		npc_personality = "Thủy thủ già thích biển cả, thường xuyên loanh quanh ở bến tàu. Ở nhà trọ bến tàu."
		schedule = { 6: "home_f", 8: "dock", 11: "dining_hall", 14: "dock", 18: "cafe_entrance", 22: "home_f" }
	elif npc_name == "Cư dân 6":
		npc_name = "Pha chế David"
		npc_personality = "Nhân viên pha chế vui tính, đam mê cà phê và bánh ngọt. Chồng của Sarah."
		schedule = { 6: "home_e", 8: "cafe_entrance", 15: "park_center", 17: "cafe_entrance", 22: "home_e" }
	elif npc_name == "Cư dân 7":
		npc_name = "Kiến trúc sư Sarah"
		npc_personality = "Đang thiết kế lại thị trấn, thường đi khảo sát tòa thị chính. Vợ của David."
		schedule = { 6: "home_e", 8: "town_hall", 12: "market", 15: "park_center", 18: "town_hall", 21: "home_e" }

	npc_memory["name"] = npc_name
	npc_memory["personality"] = npc_personality
	
	if npc_sprite != null:
		sprite.texture = npc_sprite
		
	# Tạo nhãn tên nổi trên đầu
	var font = DynamicFont.new()
	font.font_data = load("res://assets/ARIAL.TTF")
	font.size = 20
	font.use_filter = true
	
	var name_label = Label.new()
	name_label.text = npc_name
	name_label.add_font_override("font", font)
	name_label.align = Label.ALIGN_CENTER
	name_label.valign = Label.ALIGN_CENTER
	name_label.rect_min_size = Vector2(160, 24)
	name_label.rect_position = Vector2(-80, -65)
	name_label.modulate = Color(1, 0.9, 0.4) # Màu vàng nhạt
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	name_label.add_stylebox_override("normal", style)
	
	add_child(name_label)
	
	if not llm_client.is_connected("response_received", self, "_on_llm_response"):
		llm_client.connect("response_received", self, "_on_llm_response")
	
	prompt_label.hide()
	detection_zone.connect("body_entered", self, "_on_body_entered")
	detection_zone.connect("body_exited", self, "_on_body_exited")
	
	TimeManager.connect("time_changed", self, "_on_time_changed")
	TimeManager.connect("weather_changed", self, "_on_weather_changed")
	
	base_wander_position = global_position
	start_idle_routine()

func _disable_npc_collisions():
	for n in get_tree().get_nodes_in_group("npcs"):
		if n != self and n is KinematicBody2D:
			add_collision_exception_with(n)

func update_schedule(hour, force_update = false):
	if current_schedule_hour == hour and not force_update:
		return
		
	current_schedule_hour = hour
	var loc_name = ""
	
	if TimeManager.is_raining:
		loc_name = "cafe_entrance"
		move_speed = 150.0 
	else:
		move_speed = 80.0
		var target_hour = -1
		for h in schedule.keys():
			if h <= hour and h > target_hour:
				target_hour = h
		
		if target_hour != -1:
			loc_name = schedule[target_hour]
		else:
			var max_h = -1
			for h in schedule.keys():
				if h > max_h:
					max_h = h
			if max_h != -1:
				loc_name = schedule[max_h]
			else:
				loc_name = "park_center"
				
	if loc_name == "": return
			
	var map = get_node_or_null("/root/World/CollisionMap")
	if map != null and map.has_method("get_location_data"):
		var loc_data = map.get_location_data(loc_name)
		if loc_data != null:
			if typeof(loc_data) == TYPE_DICTIONARY:
				final_destination = loc_data["final_pos"]
				entrance_door_pos = loc_data["door_pos"]
			else:
				final_destination = loc_data
				entrance_door_pos = Vector2.ZERO
				
			base_wander_position = final_destination
			reevaluate_path()
			current_state = State.WALKING
			if TimeManager.is_raining:
				add_personal_log("Trời đang mưa, tôi cần chạy vội đi trú ở " + loc_name + ".")
			else:
				add_personal_log("Tôi cần đi đến " + loc_name + " lúc " + str(hour) + " giờ.")

func reevaluate_path():
	var am_i_inside = global_position.x > 5000
	var is_dest_inside = final_destination.x > 5000
	
	if am_i_inside and not is_dest_inside:
		var nearest_exit = get_nearest_exit_door()
		if nearest_exit != Vector2.ZERO:
			target_position = nearest_exit
			base_wander_position = nearest_exit
		else:
			target_position = final_destination
			base_wander_position = final_destination
			
	elif not am_i_inside and is_dest_inside:
		if entrance_door_pos != Vector2.ZERO:
			target_position = entrance_door_pos
			base_wander_position = entrance_door_pos
		else:
			target_position = final_destination
			base_wander_position = final_destination
			
	elif am_i_inside and is_dest_inside:
		# Đang ở trong phòng, đích cũng ở trong phòng, nhưng liệu có phải CÙNG 1 phòng không?
		if not is_same_room(global_position, final_destination):
			var nearest_exit = get_nearest_exit_door()
			if nearest_exit != Vector2.ZERO:
				target_position = nearest_exit
				base_wander_position = nearest_exit
			else:
				target_position = final_destination
				base_wander_position = final_destination
		else:
			target_position = final_destination
			base_wander_position = final_destination
			
	else:
		# Đang ở ngoài đường, đích cũng ở ngoài đường
		target_position = final_destination
		base_wander_position = final_destination
		
	request_path(target_position)

func get_nearest_exit_door() -> Vector2:
	var doors = get_tree().get_nodes_in_group("doors")
	
	var bgs = []
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player != null and "interior_backgrounds" in player:
		bgs = player.interior_backgrounds
			
	# Tìm phòng mà NPC đang đứng
	var current_room_rect = Rect2()
	var found_room = false
	for bg in bgs:
		if is_instance_valid(bg) and bg.texture != null:
			var rect = Rect2(bg.global_position, bg.texture.get_size())
			if rect.has_point(global_position):
				current_room_rect = rect
				found_room = true
				break
				
	var nearest_pos = Vector2.ZERO
	var min_dist = 999999.0
	
	for d in doors:
		if d.global_position.x > 5000:
			# Ưu tiên cửa nằm cùng phòng với NPC
			if found_room and not current_room_rect.has_point(d.global_position):
				continue
				
			var dist = global_position.distance_to(d.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_pos = d.global_position
				
	# Fallback an toàn nếu lỗi bounding box
	if nearest_pos == Vector2.ZERO:
		for d in doors:
			if d.global_position.x > 5000:
				var dist = global_position.distance_to(d.global_position)
				if dist < min_dist:
					min_dist = dist
					nearest_pos = d.global_position
					
	return nearest_pos

func is_same_room(pos1: Vector2, pos2: Vector2) -> bool:
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player != null and "interior_backgrounds" in player:
		for bg in player.interior_backgrounds:
			if is_instance_valid(bg) and bg.texture != null:
				var rect = Rect2(bg.global_position, bg.texture.get_size())
				if rect.has_point(pos1) and rect.has_point(pos2):
					return true
	return false

func on_teleported():
	reevaluate_path()

func _on_time_changed(hour, _minute):
	update_schedule(hour, false)

func _on_weather_changed(_is_raining):
	update_schedule(TimeManager.game_hour, true)

func _process(delta):
	if npc_cooldown > 0:
		npc_cooldown -= delta

	if player_near and Input.is_action_just_pressed("interact"):
		if current_state != State.TALKING:
			face_target(player_node.global_position)
			prompt_label.hide()
			
			if current_state == State.CRYING:
				add_personal_log("Đã có người chơi đến an ủi tôi, tôi cảm thấy đỡ hơn một chút.")
			
			current_state = State.TALKING
			velocity = Vector2.ZERO
			ChatUI.open_chat(self)
			
	# Tự động trò chuyện với NPC khác
	if not player_near and nearby_npcs.size() > 0 and current_state == State.IDLE and npc_cooldown <= 0:
		var other_npc = nearby_npcs[0]
		if other_npc.current_state == State.IDLE and other_npc.npc_cooldown <= 0:
			initiate_npc_chat(other_npc)

var current_path = []

func _physics_process(delta):
	match current_state:
		State.WALKING:
			if current_path.size() > 0:
				var next_point = current_path[0]
				var distance_to_target = global_position.distance_to(next_point)
				if distance_to_target > 5.0:
					var direction = (next_point - global_position).normalized()
					velocity = direction * move_speed
					velocity = move_and_slide(velocity)
				else:
					current_path.pop_front()
			else:
				start_idle_routine()
		State.IDLE, State.TALKING, State.WAITING_FOR_PLAYER, State.CRYING:
			velocity = Vector2.ZERO
			
	update_animation(delta)

func request_path(target: Vector2):
	var map = get_node_or_null("/root/World/CollisionMap")
	if map != null and map.has_method("get_path_to_target"):
		var p = map.get_path_to_target(global_position, target)
		if p.size() > 0:
			current_path = Array(p)
			if current_path.size() > 1 and global_position.distance_to(current_path[0]) < 10:
				current_path.pop_front()
			# Luôn ghim mục tiêu cuối cùng là đích đến chính xác để NPC bước hẳn vào Area2D của cửa
			if current_path.size() == 0 or current_path.back().distance_to(target) > 5.0:
				current_path.append(target)
		else:
			current_path = [target]
	else:
		current_path = [target]

func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		player_node = body
		if current_state != State.TALKING:
			if current_state != State.CRYING:
				current_state = State.WAITING_FOR_PLAYER
			velocity = Vector2.ZERO
			update_animation(0)
			prompt_label.show()
	elif body.has_method("receive_npc_message") and body != self:
		nearby_npcs.append(body)

func _on_body_exited(body):
	if body.name == "Player":
		player_near = false
		player_node = null
		if current_state != State.TALKING and current_state != State.CRYING:
			prompt_label.hide()
			start_idle_routine()
	elif body in nearby_npcs:
		nearby_npcs.erase(body)

func initiate_npc_chat(other_npc):
	if randf() > 0.7: return 
	
	npc_cooldown = 45.0
	other_npc.npc_cooldown = 45.0
	
	current_state = State.TALKING
	other_npc.current_state = State.TALKING
	velocity = Vector2.ZERO
	other_npc.velocity = Vector2.ZERO
	
	face_target(other_npc.global_position)
	other_npc.face_target(global_position)
	
	chat_partner = other_npc
	speech_bubble.show_text("...")
	
	var prompt = "Bạn là " + npc_memory["name"] + ". Bạn vừa gặp " + other_npc.npc_name + ".\n"
	prompt += "Tính cách của bạn: " + npc_memory["personality"] + "\n"
	prompt += "Ký ức của bạn: " + str(npc_memory["history_logs"]) + "\n"
	prompt += "Hãy nói 1 câu chào hỏi tự nhiên (dưới 15 từ)."
	llm_client.fetch_llm("npc_greeting", prompt, "")

func receive_npc_message(text: String, sender_npc):
	current_state = State.TALKING
	velocity = Vector2.ZERO
	if is_instance_valid(sender_npc):
		face_target(sender_npc.global_position)
		chat_partner = sender_npc
	
	add_personal_log(sender_npc.npc_name + " đã nói: " + text)
	speech_bubble.show_text("...")
	
	var prompt = "Bạn là " + npc_memory["name"] + ". " + sender_npc.npc_name + " vừa nói với bạn: '" + text + "'.\n"
	prompt += "Tính cách: " + npc_memory["personality"] + "\n"
	prompt += "Ký ức của bạn: " + str(npc_memory["history_logs"]) + "\n"
	prompt += "Hãy đáp lại tự nhiên (dưới 15 từ)."
	llm_client.fetch_llm("npc_reply", prompt, "")

func receive_message(text: String):
	chat_partner = null
	speech_bubble.show_text("...")
	
	var prompt = generate_system_prompt()
	add_personal_log("Player nói: " + text)
	WorldLog.add_entry("Player nói với " + npc_name + ": " + text)
	llm_client.fetch_llm("chat", prompt, text)

func _on_world_event_received(event_desc: String):
	add_personal_log("Sự kiện thế giới: " + event_desc)
	
	if "cúp điện" in event_desc.to_lower() or "mất điện" in event_desc.to_lower():
		add_personal_log("Mất điện rồi! Tôi phải chạy ra Sảnh Trung Tâm (Công viên) xem tình hình thế nào.")
		# Phân tán ngẫu nhiên xung quanh khu vực (2959, 1843) đến (3035, 2935)
		schedule[TimeManager.game_hour] = "town_square" 
		update_schedule(TimeManager.game_hour, true)
	elif randf() > 0.5:
		var loc = "town_hall" if randf() > 0.5 else "town_square"
		add_personal_log("Tôi quyết định tới " + loc + " để biểu tình/bàn tán về sự kiện này.")
		schedule[TimeManager.game_hour] = loc
		update_schedule(TimeManager.game_hour, true)
	else:
		var prompt = "Sự kiện vừa xảy ra: " + event_desc + ". Bạn cảm thấy thế nào? Trả lời 1 câu ngắn gọn (dưới 15 từ)."
		llm_client.fetch_llm("event_reaction", prompt, "")

func _on_llm_response(action: String, text_output: String):
	if action == "chat":
		var final_text = text_output
		if final_text.begins_with("[SOLVED]") or final_text.find("[SOLVED]") != -1:
			final_text = final_text.replace("[SOLVED]", "").strip_edges()
			add_personal_log("Player đã tuyệt vời giúp tôi giải quyết rắc rối cá nhân, tôi rất vui và biết ơn.")
			WorldLog.add_entry(npc_name + " đã hết buồn bã nhờ sự giúp đỡ của Player.")
			# Giải thoát khỏi trạng thái khóc lóc
			if current_state == State.CRYING:
				current_state = State.WAITING_FOR_PLAYER
				
		speech_bubble.show_text(final_text)
		add_personal_log("Tôi đã trả lời Player: " + final_text)
		ChatUI.add_npc_reply(final_text)
		
	elif action == "npc_greeting":
		speech_bubble.show_text(text_output)
		add_personal_log("Tôi nói với " + chat_partner.npc_name + ": " + text_output)
		WorldLog.add_entry(npc_name + " nói với " + chat_partner.npc_name + " ở ngoài đường.")
		
		yield(get_tree().create_timer(3.0), "timeout")
		if is_instance_valid(chat_partner):
			chat_partner.receive_npc_message(text_output, self)
			
	elif action == "npc_reply":
		speech_bubble.show_text(text_output)
		add_personal_log("Tôi đáp lại " + chat_partner.npc_name + ": " + text_output)
		
		yield(get_tree().create_timer(3.0), "timeout")
		start_idle_routine()
		if is_instance_valid(chat_partner):
			chat_partner.start_idle_routine()
			
	elif action == "event_reaction":
		speech_bubble.show_text(text_output)
		add_personal_log("Nhận xét của tôi về sự kiện: " + text_output)
		WorldLog.add_entry(npc_name + " lầm bầm: " + text_output)
		yield(get_tree().create_timer(5.0), "timeout")
		start_idle_routine()

func end_chat():
	if player_near:
		current_state = State.WAITING_FOR_PLAYER
		prompt_label.show()
	else:
		start_idle_routine()

func face_target(target_pos: Vector2):
	var dir = (target_pos - global_position).normalized()
	if abs(dir.x) > abs(dir.y):
		current_dir = 1 if dir.x > 0 else 3
	else:
		current_dir = 0 if dir.y > 0 else 2
	sprite.frame = current_dir * 4

func update_animation(delta):
	if velocity.length() > 0:
		face_target(global_position + velocity)
		anim_timer += delta
		if anim_timer >= 0.15:
			anim_timer = 0.0
			frame_index = (frame_index + 1) % 4
	else:
		frame_index = 0
	sprite.frame = current_dir * 4 + frame_index

func start_idle_routine():
	if current_state == State.CRYING:
		return # Không tự ý rời khỏi trạng thái khóc lóc
		
	current_state = State.IDLE
	var wait_time = 3.0
	if TimeManager.is_raining:
		wait_time = 0.5 
		
	yield(get_tree().create_timer(wait_time), "timeout")
	if current_state == State.IDLE:
		# Tỉ lệ 10% sinh sự (Drama)
		if randf() < 0.1 and nearby_npcs.size() == 0 and not TimeManager.is_raining:
			_trigger_random_drama()
		else:
			set_random_target()
			current_state = State.WALKING

func _trigger_random_drama():
	var dramas = ["crying", "fight", "ask_out", "steal"]
	var type = dramas[randi() % dramas.size()]
	
	if type == "crying":
		var reasons = ["bị rớt mất ví tiền", "nhớ người yêu cũ", "bị mất chiếc nhẫn kỷ niệm", "làm rơi cái bánh kem"]
		var reason = reasons[randi() % reasons.size()]
		current_state = State.CRYING
		velocity = Vector2.ZERO
		var event_str = "Tôi đang đứng khóc nức nở vì " + reason + "."
		add_personal_log(event_str)
		WorldLog.add_entry("Cảnh báo: " + npc_name + " đang khóc nức nở. Hãy đến an ủi!")
		speech_bubble.show_text("Huhu... 😭")
	else:
		var npcs = get_tree().get_nodes_in_group("npcs")
		var target = null
		for n in npcs:
			if n != self and n.current_state != State.CRYING:
				target = n
				break
				
		if target:
			if type == "fight":
				add_personal_log("Tôi vừa cãi nhau to và suýt đánh " + target.npc_name + " vì một hiểu lầm nhỏ.")
				target.add_personal_log(npc_name + " tự nhiên kiếm chuyện cãi nhau với tôi.")
				WorldLog.add_entry(npc_name + " và " + target.npc_name + " vừa cãi nhau to!")
			elif type == "ask_out":
				add_personal_log("Tôi vừa nhắn tin rủ " + target.npc_name + " đi chơi cuối tuần.")
				target.add_personal_log(npc_name + " vừa rủ tôi đi chơi, tôi hơi bất ngờ.")
				WorldLog.add_entry(npc_name + " đang tán tỉnh " + target.npc_name + ".")
			elif type == "steal":
				add_personal_log("Tôi vừa lén cướp miếng bánh ngọt của " + target.npc_name + ".")
				target.add_personal_log("Tôi bị " + npc_name + " giật mất miếng bánh ngọt, thật đáng ghét!")
				WorldLog.add_entry(npc_name + " vừa cướp đồ ăn của " + target.npc_name + ".")
				
		set_random_target()
		current_state = State.WALKING

func set_random_target():
	var random_x = rand_range(-80.0, 80.0)
	var random_y = rand_range(-80.0, 80.0)
	
	# Khu vực công viên trải dài từ (2959, 1843) xuống (3035, 2935)
	if abs(base_wander_position.x - 2959) < 100 and abs(base_wander_position.y - 1843) < 100:
		random_x = rand_range(-50.0, 100.0)
		random_y = rand_range(0.0, 1000.0)
	elif abs(base_wander_position.x - 3000) < 100 and abs(base_wander_position.y - 2300) < 100:
		random_x = rand_range(-50.0, 100.0)
		random_y = rand_range(-400.0, 600.0)
		
	target_position = base_wander_position + Vector2(random_x, random_y)
	request_path(target_position)

func add_personal_log(event_text: String):
	npc_memory["history_logs"].append(event_text)
	if npc_memory["history_logs"].size() > 10:
		npc_memory["history_logs"].pop_front()

func generate_system_prompt() -> String:
	var prompt = "Bạn là nhân vật trong game tên là " + npc_memory["name"] + ". Thời gian: " + TimeManager.get_time_string() + "\n"
	if TimeManager.is_raining:
		prompt += "Thời tiết: Đang mưa rất to.\n"
	else:
		prompt += "Thời tiết: Nắng ráo đẹp trời.\n"
		
	prompt += "Tính cách: " + npc_memory["personality"] + ".\n"
	prompt += "Tin tức thị trấn:\n" + WorldLog.get_recent_logs(3)
	
	if npc_memory["history_logs"].size() > 0:
		prompt += "Ký ức gần đây của bạn:\n"
		for entry in npc_memory["history_logs"]:
			prompt += "- " + entry + "\n"
			
	prompt += "Hãy nhập vai và trả lời tự nhiên, ngắn gọn bằng tiếng Việt dưới 20 từ. "
	
	if current_state == State.CRYING:
		prompt += "Bạn đang khóc lóc vì một rắc rối cá nhân. Nếu Player chưa giải quyết, hãy than vãn và nhờ giúp đỡ. NẾU Player ĐÃ ĐƯA RA CÁCH GIẢI QUYẾT hợp lý (ví dụ: tìm thấy đồ, mua cho đồ mới, an ủi hợp lý), hãy vui vẻ cảm ơn, chấp nhận và BẮT BUỘC bắt đầu câu trả lời của bạn bằng từ khóa [SOLVED]."
		
	return prompt
