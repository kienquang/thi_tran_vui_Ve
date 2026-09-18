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

enum State { IDLE, WALKING, TALKING, WAITING_FOR_PLAYER }
var current_state = State.IDLE

export var move_speed = 80.0
var target_position = Vector2.ZERO
var base_wander_position = Vector2.ZERO
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
	randomize()
	npc_memory["name"] = npc_name
	npc_memory["personality"] = npc_personality
	
	if npc_sprite != null:
		sprite.texture = npc_sprite
	
	if not llm_client.is_connected("response_received", self, "_on_llm_response"):
		llm_client.connect("response_received", self, "_on_llm_response")
	
	prompt_label.hide()
	detection_zone.connect("body_entered", self, "_on_body_entered")
	detection_zone.connect("body_exited", self, "_on_body_exited")
	
	TimeManager.connect("time_changed", self, "_on_time_changed")
	TimeManager.connect("weather_changed", self, "_on_weather_changed")
	
	base_wander_position = global_position
	start_idle_routine()

func update_schedule(hour, force_update = false):
	# Chỉ cập nhật lịch trình khi chuyển sang giờ mới hoặc thời tiết thay đổi
	if current_schedule_hour == hour and not force_update:
		return
		
	current_schedule_hour = hour
	var loc_name = ""
	
	# SỰ KIỆN ƯU TIÊN: TRÚ MƯA
	if TimeManager.is_raining:
		loc_name = "cafe_entrance"
		move_speed = 150.0 # Chạy nhanh khi mưa
	elif schedule.has(hour):
		loc_name = schedule[hour]
		move_speed = 80.0
	else:
		move_speed = 80.0
		if hour >= 6 and hour < 9:
			loc_name = "park_center"
		elif hour >= 9 and hour < 12:
			loc_name = "cafe_entrance"
		elif hour >= 12 and hour < 18:
			loc_name = "park_center"
		elif hour >= 18 and hour < 22:
			loc_name = "cafe_entrance"
		else:
			loc_name = "mayor_house" # Đi ngủ
			
	var map = get_node_or_null("/root/World/CollisionMap")
	if map != null and map.has_method("get_location"):
		var loc = map.get_location(loc_name)
		if loc != Vector2.ZERO:
			base_wander_position = loc
			target_position = base_wander_position
			current_state = State.WALKING
			if TimeManager.is_raining:
				add_personal_log("Trời đang mưa, tôi cần chạy vội đi trú ở " + loc_name + ".")
			else:
				add_personal_log("Tôi cần đi đến " + loc_name + " lúc " + str(hour) + " giờ.")

func _on_time_changed(hour, _minute):
	# Kiểm tra lịch trình mỗi giờ
	update_schedule(hour, false)

func _on_weather_changed(_is_raining):
	# Bắt buộc thay đổi lịch trình ngay lập tức khi nắng/mưa
	update_schedule(TimeManager.game_hour, true)

func _process(delta):
	if npc_cooldown > 0:
		npc_cooldown -= delta

	if player_near and Input.is_action_just_pressed("interact"):
		if current_state != State.TALKING:
			face_target(player_node.global_position)
			prompt_label.hide()
			current_state = State.TALKING
			velocity = Vector2.ZERO
			ChatUI.open_chat(self)
			
	# Tự động trò chuyện với NPC khác
	if not player_near and nearby_npcs.size() > 0 and current_state == State.IDLE and npc_cooldown <= 0:
		var other_npc = nearby_npcs[0]
		if other_npc.current_state == State.IDLE and other_npc.npc_cooldown <= 0:
			initiate_npc_chat(other_npc)

func _physics_process(delta):
	match current_state:
		State.WALKING:
			var distance_to_target = global_position.distance_to(target_position)
			if distance_to_target > 2.0:
				var direction = (target_position - global_position).normalized()
				velocity = direction * move_speed
				velocity = move_and_slide(velocity)
			else:
				start_idle_routine()
		State.IDLE, State.TALKING, State.WAITING_FOR_PLAYER:
			velocity = Vector2.ZERO
			
	update_animation(delta)

# --- Xử lý sự kiện khi Player/NPC lại gần ---
func _on_body_entered(body):
	if body.name == "Player":
		player_near = true
		player_node = body
		if current_state != State.TALKING:
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
		if current_state != State.TALKING:
			prompt_label.hide()
			start_idle_routine()
	elif body in nearby_npcs:
		nearby_npcs.erase(body)

# --- NPC-NPC Chat (Tiết kiệm Token LLM) ---
var default_greetings = [
	"Chào bạn, thời tiết hôm nay thật đẹp nhỉ!",
	"Chào, bạn đang đi đâu đó?",
	"Ồ, rất vui được gặp bạn ở đây.",
	"Bạn ăn sáng chưa?",
	"Dạo này công việc thế nào rồi?"
]

var default_responses = [
	"Tôi cũng thấy vậy, thật tuyệt!",
	"Tôi đang đi dạo một chút cho khuây khỏa.",
	"Mọi thứ vẫn ổn, cảm ơn bạn nhé.",
	"Cũng bình thường thôi. Hẹn gặp lại sau!",
	"Chào nhé, tôi đang hơi bận một chút."
]

func initiate_npc_chat(other_npc):
	if randf() > 0.7: return # Tỷ lệ ngẫu nhiên bắt chuyện
	
	npc_cooldown = 45.0
	other_npc.npc_cooldown = 45.0
	
	current_state = State.TALKING
	other_npc.current_state = State.TALKING
	velocity = Vector2.ZERO
	other_npc.velocity = Vector2.ZERO
	
	face_target(other_npc.global_position)
	other_npc.face_target(global_position)
	
	# Chọn câu chào mặc định
	var greeting = default_greetings[randi() % default_greetings.size()]
	speech_bubble.show_text(greeting)
	add_personal_log("Tôi đã chào " + other_npc.npc_name + ": " + greeting)
	
	# Đợi 3 giây rồi cho NPC kia trả lời
	yield(get_tree().create_timer(3.0), "timeout")
	if is_instance_valid(other_npc):
		other_npc.receive_npc_message(greeting, self)

func receive_npc_message(text: String, sender_npc):
	current_state = State.TALKING
	velocity = Vector2.ZERO
	if is_instance_valid(sender_npc):
		face_target(sender_npc.global_position)
	
	add_personal_log(sender_npc.npc_name + " đã nói với tôi: " + text)
	
	# Chọn câu trả lời mặc định
	var response = default_responses[randi() % default_responses.size()]
	speech_bubble.show_text(response)
	add_personal_log("Tôi đã trả lời: " + response)
	
	# Đợi 3 giây rồi cả hai đường ai nấy đi
	yield(get_tree().create_timer(3.0), "timeout")
	
	start_idle_routine()
	if is_instance_valid(sender_npc):
		sender_npc.start_idle_routine()

# --- Xử lý Chat với Player ---
func receive_message(text: String):
	chat_partner = null
	speech_bubble.show_text("...")
	
	var prompt = generate_system_prompt()
	add_personal_log("Người chơi nói: " + text)
	WorldLog.add_entry("Người chơi nói với " + npc_name + ": " + text)
	llm_client.fetch_llm_dialogue(prompt, text)

func _on_llm_response(text_output: String):
	speech_bubble.show_text(text_output)
	add_personal_log("Tôi đã trả lời: " + text_output)
	ChatUI.add_npc_reply(text_output)

func end_chat():
	if player_near:
		current_state = State.WAITING_FOR_PLAYER
		prompt_label.show()
	else:
		start_idle_routine()

# --- Hỗ trợ di chuyển ---
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
	current_state = State.IDLE
	var wait_time = 3.0
	if TimeManager.is_raining:
		wait_time = 0.5 # Trời mưa thì không đứng chơi, chạy liên tục
		
	yield(get_tree().create_timer(wait_time), "timeout")
	if current_state == State.IDLE:
		set_random_target()
		current_state = State.WALKING

func set_random_target():
	var random_x = rand_range(-80.0, 80.0)
	var random_y = rand_range(-80.0, 80.0)
	target_position = base_wander_position + Vector2(random_x, random_y)

func add_personal_log(event_text: String):
	npc_memory["history_logs"].append(event_text)
	if npc_memory["history_logs"].size() > 10:
		npc_memory["history_logs"].pop_front()

func generate_system_prompt() -> String:
	var prompt = "Bạn là nhân vật trong game tên là " + npc_memory["name"] + ". Thời gian hiện tại: " + TimeManager.get_time_string() + "\n"
	if TimeManager.is_raining:
		prompt += "Thời tiết: Đang mưa rất to, bạn đang phải đi trú mưa.\n"
	else:
		prompt += "Thời tiết: Nắng ráo đẹp trời.\n"
		
	prompt += "Tính cách: " + npc_memory["personality"] + ".\n"
	if npc_memory["relationships"].size() > 0:
		prompt += "Quan hệ với mọi người: " + JSON.print(npc_memory["relationships"]) + "\n"
	
	prompt += "Tin tức thị trấn gần đây:\n" + WorldLog.get_recent_logs(3)
	
	if npc_memory["history_logs"].size() > 0:
		prompt += "Ký ức của riêng bạn:\n"
		for entry in npc_memory["history_logs"]:
			prompt += "- " + entry + "\n"
	prompt += "Hãy nhập vai và trả lời tự nhiên, ngắn gọn bằng tiếng Việt dưới 20 từ."
	return prompt
