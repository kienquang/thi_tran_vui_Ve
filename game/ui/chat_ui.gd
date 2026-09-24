extends CanvasLayer

onready var panel = $Panel
onready var line_edit = $Panel/LineEdit
onready var send_btn = $Panel/SendButton
onready var close_btn = $Panel/CloseButton
onready var chat_history = $Panel/ChatHistory
onready var time_label = $TimeLabel

var current_npc = null
var font: DynamicFont
var font_sm: DynamicFont
var extra_buttons = []

func _ready():
	font = DynamicFont.new()
	font.font_data = load("res://assets/ARIAL.TTF")
	font.size = 14
	font.use_filter = true
	
	font_sm = DynamicFont.new()
	font_sm.font_data = load("res://assets/ARIAL.TTF")
	font_sm.size = 12
	font_sm.use_filter = true
	
	line_edit.add_font_override("font", font)
	send_btn.add_font_override("font", font)
	close_btn.add_font_override("font", font)
	chat_history.add_font_override("normal_font", font)
	time_label.add_font_override("font", font_sm)
	
	UIUtils.style_button(send_btn, Color(0.18, 0.5, 0.25))
	UIUtils.style_button(close_btn, Color(0.55, 0.18, 0.18))
	
	panel.hide()
	send_btn.connect("pressed", self, "_on_send_pressed")
	close_btn.connect("pressed", self, "_on_close_pressed")
	line_edit.connect("text_entered", self, "_on_text_entered")
	
	TimeManager.connect("time_changed", self, "_on_time_changed")
	_on_time_changed(TimeManager.game_hour, TimeManager.game_minute)

func _on_time_changed(hour, minute):
	time_label.text = "%02d:%02d" % [hour, minute]

func open_chat(npc_node):
	current_npc = npc_node
	panel.show()
	chat_history.bbcode_text = "[color=#FFFF88][" + current_npc.npc_name + "][/color]\n"
	line_edit.text = ""
	_clear_extra_buttons()
	
	# Danh dau progress quest DELIVER
	QuestManager.mark_npc_talked(npc_node.npc_name)
	
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	
	# Uu tien: kiem tra hoan thanh quest
	if player != null and QuestManager.can_complete_at(current_npc.npc_name, player.inventory):
		_show_complete_button()
		return
	
	# NPC co quest chua phat => hien ngay
	if current_npc.pending_quest != null and not QuestManager.has_active_from(current_npc.npc_name):
		_show_quest_offer(current_npc.pending_quest)
		return
	
	# Shop => hien nut mua hang
	if QuestManager.is_shop(current_npc.npc_name):
		_show_shop_button()
	
	line_edit.grab_focus()

func _show_quest_offer(quest: Dictionary):
	chat_history.bbcode_text += "[color=#FFD700]>> Nhiem vu: " + quest["title"] + "[/color]\n"
	chat_history.bbcode_text += "[color=#EEEEEE]" + quest["desc"] + "[/color]\n"
	chat_history.bbcode_text += "[color=#AAFFAA]Thuong: " + str(quest["reward_coins"]) + " xu[/color]\n"
	chat_history.bbcode_text += "[color=#AAAAAA]Ban co muon nhan khong?[/color]"
	
	var btn_accept = _make_btn("Nhan nhiem vu", Color(0.2, 0.55, 0.25), "_on_quest_accept")
	btn_accept.rect_position = Vector2(15, 303)
	btn_accept.rect_size = Vector2(160, 32)
	panel.add_child(btn_accept)
	extra_buttons.append(btn_accept)
	
	var btn_decline = _make_btn("Tu choi", Color(0.55, 0.2, 0.2), "_on_quest_decline")
	btn_decline.rect_position = Vector2(185, 303)
	btn_decline.rect_size = Vector2(110, 32)
	panel.add_child(btn_decline)
	extra_buttons.append(btn_decline)

func _show_complete_button():
	var q = QuestManager.get_active_from(current_npc.npc_name)
	var lbl = "Giao do"
	if not q.empty() and q.get("type") == QuestManager.QuestType.DELIVER_MSG:
		lbl = "Bao cao hoan thanh"
	chat_history.bbcode_text += "[color=#AAFFAA]>> Ban da hoan thanh nhiem vu! Hay giao cho " + current_npc.npc_name + ".[/color]"
	var btn_done = _make_btn(lbl, Color(0.65, 0.45, 0.05), "_on_quest_complete")
	btn_done.rect_position = Vector2(15, 303)
	btn_done.rect_size = Vector2(280, 32)
	panel.add_child(btn_done)
	extra_buttons.append(btn_done)

func _show_shop_button():
	var btn_shop = _make_btn("Xem hang ban", Color(0.5, 0.3, 0.05), "_on_shop_open")
	btn_shop.rect_position = Vector2(15, 303)
	btn_shop.rect_size = Vector2(190, 32)
	panel.add_child(btn_shop)
	extra_buttons.append(btn_shop)

func _make_btn(txt: String, color: Color, cb: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.add_font_override("font", font)
	UIUtils.style_button(btn, color)
	btn.connect("pressed", self, cb)
	return btn

func _on_quest_accept():
	if current_npc == null or current_npc.pending_quest == null:
		return
	QuestManager.accept_quest(current_npc.pending_quest)
	current_npc.clear_pending_quest()
	_clear_extra_buttons()
	chat_history.bbcode_text += "\n[color=#AAFFAA]Da nhan nhiem vu![/color]"
	current_npc.receive_message("Toi da nhan nhiem vu cua ban.")

func _on_quest_decline():
	_clear_extra_buttons()
	chat_history.bbcode_text += "\n[color=#AAAAAA]Ban da tu choi nhiem vu."
	line_edit.grab_focus()

func _on_quest_complete():
	if current_npc == null:
		return
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player == null:
		return
	var q = QuestManager.get_active_from(current_npc.npc_name)
	if not q.empty() and q.get("type") == QuestManager.QuestType.FETCH_ITEM:
		player.remove_item(q.get("required_item", ""), 1)
	var reward = QuestManager.complete_quest_at(current_npc.npc_name)
	player.add_coins(reward)
	_clear_extra_buttons()
	chat_history.bbcode_text += "\n[color=#FFD700]Hoan thanh! Nhan " + str(reward) + " xu![/color]"
	current_npc.receive_message("Cam on ban rat nhieu!")

func _on_shop_open():
	if current_npc == null:
		return
	var items = QuestManager.get_shop_items(current_npc.npc_name)
	chat_history.bbcode_text += "\n[color=#FFD700]--- Hang ban ---[/color]"
	for i in range(items.size()):
		chat_history.bbcode_text += "\n[color=#EEEEEE]" + str(i+1) + ". " + items[i]["display"] + " - " + str(items[i]["price"]) + " xu[/color]"
	chat_history.bbcode_text += "\n[color=#AAAAAA]Nhap so de mua:[/color]"
	_clear_extra_buttons()
	line_edit.placeholder_text = "Nhap so (1-" + str(items.size()) + ")..."
	if line_edit.is_connected("text_entered", self, "_on_text_entered"):
		line_edit.disconnect("text_entered", self, "_on_text_entered")
	if not line_edit.is_connected("text_entered", self, "_on_buy_input"):
		line_edit.connect("text_entered", self, "_on_buy_input")
	line_edit.grab_focus()

func _on_buy_input(text: String):
	line_edit.text = ""
	line_edit.placeholder_text = "Nhap tin nhan..."
	if line_edit.is_connected("text_entered", self, "_on_buy_input"):
		line_edit.disconnect("text_entered", self, "_on_buy_input")
	if not line_edit.is_connected("text_entered", self, "_on_text_entered"):
		line_edit.connect("text_entered", self, "_on_text_entered")
	if current_npc == null:
		return
	var items = QuestManager.get_shop_items(current_npc.npc_name)
	var idx = int(text) - 1
	if idx < 0 or idx >= items.size():
		chat_history.bbcode_text += "\n[color=#FF8888]Lua chon khong hop le.[/color]"
		return
	var item = items[idx]
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player == null:
		return
	if player.spend_coins(item["price"]):
		player.add_item(item["name"], 1)
		chat_history.bbcode_text += "\n[color=#AAFFAA]Mua thanh cong: " + item["display"] + "! Con lai: " + str(player.coins) + " xu[/color]"
		WorldLog.add_entry("Player mua " + item["display"] + " tu " + current_npc.npc_name)
	else:
		chat_history.bbcode_text += "\n[color=#FF8888]Khong du xu! (Co: " + str(player.coins) + " xu)[/color]"

func _clear_extra_buttons():
	for btn in extra_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	extra_buttons.clear()

func _on_send_pressed():
	_send_msg()

func _on_text_entered(_new_text):
	_send_msg()

func _send_msg():
	var text = line_edit.text.strip_edges()
	if text != "" and current_npc != null:
		chat_history.bbcode_text += "\n[color=#88CCFF]Ban:[/color] " + text
		current_npc.receive_message(text)
		line_edit.text = ""
		line_edit.grab_focus()

func add_npc_reply(reply_text: String):
	if current_npc != null:
		chat_history.bbcode_text += "\n[color=#88FF88]" + current_npc.npc_name + ":[/color] " + reply_text

func _on_close_pressed():
	_clear_extra_buttons()
	if line_edit.is_connected("text_entered", self, "_on_buy_input"):
		line_edit.disconnect("text_entered", self, "_on_buy_input")
	if not line_edit.is_connected("text_entered", self, "_on_text_entered"):
		line_edit.connect("text_entered", self, "_on_text_entered")
	line_edit.placeholder_text = "Nhap tin nhan..."
	panel.hide()
	if current_npc:
		current_npc.current_state = 0
		current_npc.start_idle_routine()
	current_npc = null
