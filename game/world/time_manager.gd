extends Node

signal time_changed(hour, minute)
signal day_changed(day, weekday)

var day: int = 1
var week_day: int = 0 # 0 = Monday
const WEEKDAYS = ["Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ Nhật"]

var calendar_events = {}

func get_event_for_day(d: int) -> String:
	if calendar_events.has(d):
		return calendar_events[d]
	return ""

func set_event_for_day(d: int, event_name: String):
	if event_name == "":
		calendar_events.erase(d)
	else:
		calendar_events[d] = event_name
# 6:00 Sáng
var game_hour: int = 6
var game_minute: int = 0

# 1 giây ngoài đời = 2 phút trong game (chậm hơn nhiều so với 10 phút trước đây)
export var time_scale: float = 2.0 
var timer: float = 0.0

var current_weather = "SUNNY"
var is_raining = false
signal weather_changed(weather_type)

func change_weather(type: String):
	current_weather = type
	is_raining = (type == "RAIN" or type == "STORM")
	emit_signal("weather_changed", type)
	
	if current_weather == "RAIN" or current_weather == "STORM":
		AudioManager.play_rain()
		AudioManager.stop_birds()
	elif current_weather == "SUNNY":
		AudioManager.stop_rain()
		AudioManager.play_birds()
	else:
		AudioManager.stop_rain()
		AudioManager.stop_birds()

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
			day += 1
			week_day = (week_day + 1) % 7
			emit_signal("day_changed", day, WEEKDAYS[week_day])
			
			var todays_event = get_event_for_day(day)
			if todays_event != "":
				var desc = "Hôm nay là sự kiện: " + todays_event
				var world_log = get_node_or_null("/root/WorldLog")
				if world_log:
					world_log.current_world_event = todays_event
					world_log.add_entry("SỰ KIỆN TRONG NGÀY: " + todays_event)
				for n in get_tree().get_nodes_in_group("npcs"):
					if n.has_method("_on_world_event_received"):
						n._on_world_event_received(desc)
			
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
			
		# Pha màu tùy theo thời tiết
		if current_weather == "RAIN":
			target_color = target_color.linear_interpolate(Color(0.5, 0.6, 0.7), 0.5)
		elif current_weather == "STORM":
			target_color = target_color.linear_interpolate(Color(0.2, 0.2, 0.3), 0.8)
		elif current_weather == "SNOW":
			target_color = target_color.linear_interpolate(Color(0.8, 0.9, 1.0), 0.3)
		elif current_weather == "FOG":
			target_color = target_color.linear_interpolate(Color(0.7, 0.7, 0.7), 0.6)
			
		# Chuyển màu mượt mà
		canvas_mod.color = canvas_mod.color.linear_interpolate(target_color, delta * 0.5)

func get_time_string() -> String:
	return "%02d:%02d" % [game_hour, game_minute]
