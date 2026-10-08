extends Node

var save_path = "user://savegame.json"
var load_requested = false

func save_game():
	var save_data = {}
	
	# Lưu trạng thái Thời gian
	save_data["TimeManager"] = {
		"day": TimeManager.day,
		"week_day": TimeManager.week_day,
		"current_weather": TimeManager.current_weather,
		"events": TimeManager.calendar_events
	}
	
	# Lưu trạng thái Nhiệm vụ
	save_data["QuestManager"] = {
		"active_quests": QuestManager.active_quests,
		"completed_quests": QuestManager.completed_quests
	}
	
	# Lưu trạng thái Người chơi (Xu, Túi đồ)
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player:
		save_data["Player"] = {
			"coins": player.coins,
			"inventory": player.inventory,
			"position_x": player.global_position.x,
			"position_y": player.global_position.y
		}
	else:
		# Nếu không tìm thấy player (ví dụ lưu lúc đang chuyển cảnh), lấy giá trị mặc định/cũ
		pass
		
	var file = File.new()
	if file.open(save_path, File.WRITE) == OK:
		file.store_string(to_json(save_data))
		file.close()
		print("Đã lưu game vào ", save_path)
		
		var log_node = get_tree().root.get_node_or_null("WorldLog")
		if log_node:
			log_node.add_entry("💾 Đã lưu tiến trình trò chơi!")
			
		return true
	return false

func has_save() -> bool:
	var file = File.new()
	return file.file_exists(save_path)

func load_game_data() -> Dictionary:
	var file = File.new()
	if file.open(save_path, File.READ) == OK:
		var content = file.get_as_text()
		file.close()
		var result = parse_json(content)
		if typeof(result) == TYPE_DICTIONARY:
			return result
	return {}

func apply_save_data():
	var data = load_game_data()
	if data.empty():
		return
		
	if data.has("TimeManager"):
		var t = data["TimeManager"]
		TimeManager.day = int(t.get("day", 1))
		TimeManager.week_day = int(t.get("week_day", 0))
		TimeManager.current_weather = str(t.get("current_weather", "SUNNY"))
		# Khôi phục events, json lưu key thành String nên cần parse lại thành int
		TimeManager.calendar_events.clear()
		if t.has("events"):
			var saved_events = t["events"]
			for d_str in saved_events.keys():
				TimeManager.calendar_events[int(d_str)] = saved_events[d_str]
				
	if data.has("QuestManager"):
		var q = data["QuestManager"]
		QuestManager.active_quests = q.get("active_quests", [])
		QuestManager.completed_quests = q.get("completed_quests", [])
		
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player and data.has("Player"):
		var p = data["Player"]
		player.coins = int(p.get("coins", 150))
		player.inventory = p.get("inventory", {})
		if p.has("position_x") and p.has("position_y"):
			player.global_position = Vector2(float(p["position_x"]), float(p["position_y"]))
		# Cập nhật UI ngay lập tức
		QuestUI.update_coins(player.coins)
		QuestUI.refresh_inventory(player.inventory)
	
	load_requested = false
	
	# Cập nhật lại UI thời gian
	TimeManager.emit_signal("day_changed", TimeManager.day, TimeManager.WEEKDAYS[TimeManager.week_day])
	TimeManager.emit_signal("weather_changed", TimeManager.current_weather)

func delete_save():
	var dir = Directory.new()
	if dir.file_exists(save_path):
		dir.remove(save_path)
