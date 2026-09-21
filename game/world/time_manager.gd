extends Node

signal time_changed(hour, minute)

# 6:00 Sáng
var game_hour: int = 6
var game_minute: int = 0

# 1 giây ngoài đời = 2 phút trong game (chậm hơn nhiều so với 10 phút trước đây)
export var time_scale: float = 2.0 
var timer: float = 0.0

var is_raining = false
signal weather_changed(is_raining)

func toggle_rain():
	is_raining = not is_raining
	emit_signal("weather_changed", is_raining)
	if is_raining:
		WorldLog.add_entry("Trời bỗng nhiên đổ mưa to!")
	else:
		WorldLog.add_entry("Trời đã tạnh mưa, nắng lên rực rỡ.")

func _ready():
	# Tự động đăng ký phím E làm nút tương tác nếu trong Project Settings chưa có
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev = InputEventKey.new()
		ev.scancode = KEY_E
		InputMap.action_add_event("interact", ev)

func _process(delta):
	timer += delta
	# Mỗi 1 giây thực
	if timer >= 1.0:
		timer = 0.0
		game_minute += int(time_scale)
		
		if game_minute >= 60:
			game_minute -= 60
			game_hour += 1
			
		if game_hour >= 24:
			game_hour = 0
			
		emit_signal("time_changed", game_hour, game_minute)
	
	update_lighting(delta)

func update_lighting(delta):
	var canvas_mod = get_node_or_null("/root/World/CanvasModulate")
	if canvas_mod != null:
		var target_color = Color(1.0, 1.0, 1.0) # Sáng sớm / Trưa
		
		if game_hour >= 17 and game_hour < 19:
			target_color = Color(0.8, 0.5, 0.3) # Hoàng hôn (Cam)
		elif game_hour >= 19 or game_hour < 6:
			target_color = Color(0.2, 0.2, 0.4) # Đêm (Xanh thẫm)
			
		# Chuyển màu mượt mà
		canvas_mod.color = canvas_mod.color.linear_interpolate(target_color, delta * 0.5)

func get_time_string() -> String:
	return "%02d:%02d" % [game_hour, game_minute]
