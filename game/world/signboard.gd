extends Area2D

export(String, MULTILINE) var text_content = "Nội dung bảng hiệu..."

var label = null
var player_node = null

func _ready():
	label = $PromptLabel
	label.hide()
	
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")

func _process(_delta):
	if player_node != null and Input.is_action_just_pressed("interact"):
		# Dùng SpeechBubble có sẵn của ChatUI để hiển thị cho nhanh (hoặc in ra Log)
		ChatUI.add_npc_reply("[Biển báo]: " + text_content)

func _on_body_entered(body):
	if body.name == "Player":
		player_node = body
		label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_node = null
		label.hide()
