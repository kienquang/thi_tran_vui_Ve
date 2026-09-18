extends Area2D

export(String) var prompt_text = "[E] Cầu Mưa"

var label = null
var player_node = null

func _ready():
	label = $PromptLabel
	label.hide()
	
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")

func _process(_delta):
	if player_node != null and Input.is_action_just_pressed("interact"):
		TimeManager.toggle_rain()
		if TimeManager.is_raining:
			label.text = "[E] Cầu Nắng"
			ChatUI.add_npc_reply("[Hệ Thống]: Bạn đã gọi một cơn mưa lớn đến thị trấn!")
		else:
			label.text = "[E] Cầu Mưa"
			ChatUI.add_npc_reply("[Hệ Thống]: Mây đen tan biến, trời lại hửng nắng!")
		
		# Cập nhật lại lịch trình của tất cả NPC ngay lập tức
		var npcs = get_tree().get_nodes_in_group("npcs")
		for npc in npcs:
			npc.update_schedule(TimeManager.game_hour)

func _on_body_entered(body):
	if body.name == "Player":
		player_node = body
		label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_node = null
		label.hide()
