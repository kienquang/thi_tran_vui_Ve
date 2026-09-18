extends Area2D

export var target_position = Vector2.ZERO
export var prompt_text = "[E] Đi vào"

var player_node = null
onready var label = $PromptLabel
onready var visual_rect = $ColorRect

func _ready():
	label.text = prompt_text
	label.hide()
	
	if not Engine.editor_hint:
		visual_rect.color = Color(0, 0, 0, 0)
	
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")

func _process(_delta):
	if player_node != null and Input.is_action_just_pressed("interact"):
		# Dịch chuyển Player đến tọa độ mới
		player_node.global_position = target_position
		
		# Ép Camera của Player chuyển cảnh ngay lập tức (không trượt)
		if player_node.camera != null:
			player_node.camera.reset_smoothing()

func _on_body_entered(body):
	if body.name == "Player":
		player_node = body
		label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_node = null
		label.hide()
