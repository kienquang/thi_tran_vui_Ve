extends Node

var save_path = "user://savegame.json"
var load_requested = false

func save_game():
	var save_data = {}
	
	# Lưu trạng thái Thời gian
	save_data["TimeManager"] = {
		"day": TimeManager.day,
		"week_day": TimeManager.week_day,
		"game_hour": TimeManager.game_hour,
		"game_minute": TimeManager.game_minute,
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
		
	# Lưu trạng thái Hảo cảm (Tim) và Ký ức của toàn bộ NPC
	var npcs_data = {}
	for npc in get_tree().get_nodes_in_group("npcs"):
		if "npc_name" in npc and "npc_memory" in npc:
			npcs_data[npc.npc_name] = {
				"heart_level": npc.npc_memory.get("heart_level", 0),
				"talk_count": npc.npc_memory.get("talk_count", 0),
				"last_talk_day": npc.npc_memory.get("last_talk_day", 0),
				"history_logs": npc.npc_memory.get("history_logs", [])
			}
	save_data["NPCs"] = npcs_data
		
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
		TimeManager.game_hour = int(t.get("game_hour", 6))
		TimeManager.game_minute = int(t.get("game_minute", 0))
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
		if QuestUI.has_method("_draw_quests"):
			QuestUI._draw_quests()
		
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player and data.has("Player"):
		var p = data["Player"]
		player.coins = int(p.get("coins", 150))
		player.inventory = p.get("inventory", {})
		if p.has("position_x") and p.has("position_y"):
			player.global_position = Vector2(float(p["position_x"]), float(p["position_y"]))
			if "camera" in player and player.camera:
				player.camera.global_position = player.global_position
		# Cập nhật UI ngay lập tức
		QuestUI.update_coins(player.coins)
		QuestUI.refresh_inventory(player.inventory)
		
	if data.has("NPCs"):
		var npcs_data = data["NPCs"]
		for npc in get_tree().get_nodes_in_group("npcs"):
			if "npc_name" in npc and npcs_data.has(npc.npc_name):
				var n_info = npcs_data[npc.npc_name]
				npc.npc_memory["heart_level"] = int(n_info.get("heart_level", 0))
				npc.npc_memory["talk_count"] = int(n_info.get("talk_count", 0))
				npc.npc_memory["last_talk_day"] = int(n_info.get("last_talk_day", 0))
				if n_info.has("history_logs") and typeof(n_info["history_logs"]) == TYPE_ARRAY:
					npc.npc_memory["history_logs"] = n_info["history_logs"]
	
	load_requested = false
	
	# Cập nhật lại UI thời gian
	TimeManager.emit_signal("day_changed", TimeManager.day, TimeManager.WEEKDAYS[TimeManager.week_day])
	TimeManager.emit_signal("time_changed", TimeManager.game_hour, TimeManager.game_minute)
	TimeManager.emit_signal("weather_changed", TimeManager.current_weather)

func delete_save():
	var dir = Directory.new()
	if dir.file_exists(save_path):
		dir.remove(save_path)
