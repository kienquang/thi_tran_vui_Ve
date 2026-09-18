extends CanvasLayer

onready var panel = $Panel
onready var line_edit = $Panel/LineEdit
onready var send_btn = $Panel/SendButton
onready var close_btn = $Panel/CloseButton
onready var chat_history = $Panel/ChatHistory
onready var time_label = $TimeLabel

var current_npc = null

func _ready():
	panel.hide()
	send_btn.connect("pressed", self, "_on_send_pressed")
	close_btn.connect("pressed", self, "_on_close_pressed")
	line_edit.connect("text_entered", self, "_on_text_entered")
	
	TimeManager.connect("time_changed", self, "_on_time_changed")
	_on_time_changed(TimeManager.game_hour, TimeManager.game_minute)

func _on_time_changed(hour, minute):
	time_label.text = "Thời gian: %02d:%02d" % [hour, minute]

func open_chat(npc_node):
	current_npc = npc_node
	panel.show()
	chat_history.bbcode_text = "[color=yellow]Hệ thống: Bắt đầu trò chuyện với " + current_npc.npc_name + "...[/color]\n"
	line_edit.text = ""
	line_edit.grab_focus()

func _on_send_pressed():
	_send_msg()

func _on_text_entered(_new_text):
	_send_msg()
	
func _send_msg():
	var text = line_edit.text.strip_edges()
	if text != "" and current_npc != null:
		chat_history.bbcode_text += "\n[color=lightblue]Bạn:[/color] " + text
		current_npc.receive_message(text)
		line_edit.text = ""
		line_edit.grab_focus()

func add_npc_reply(reply_text: String):
	if current_npc != null:
		chat_history.bbcode_text += "\n[color=lightgreen]" + current_npc.npc_name + ":[/color] " + reply_text

func _on_close_pressed():
	panel.hide()
	if current_npc != null:
		current_npc.end_chat()
	current_npc = null
