extends Node

signal log_added(new_log)

var global_logs = []

func add_entry(event_text: String):
	# Sử dụng TimeManager để lấy giờ game thay vì giờ thực
	var time_str = TimeManager.get_time_string()
	var full_log = "[" + time_str + "] " + event_text
	
	global_logs.append(full_log)
	
	# Giới hạn 30 sự kiện gần nhất
	if global_logs.size() > 30:
		global_logs.pop_front()
		
	emit_signal("log_added", full_log)

# Lấy các sự kiện gần đây để làm bối cảnh (gossip) cho NPC
func get_recent_logs(count: int = 5) -> String:
	var result = ""
	var start_idx = max(0, global_logs.size() - count)
	for i in range(start_idx, global_logs.size()):
		result += global_logs[i] + "\n"
	return result
