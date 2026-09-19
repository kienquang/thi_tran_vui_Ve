extends Area2D

export var target_position = Vector2.ZERO
export var prompt_text = "[E] Đi vào"
export(NodePath) var target_node_path

var player_node = null
onready var label = $PromptLabel
onready var visual_rect = $ColorRect

func _ready():
	add_to_group("doors")
	label.text = prompt_text
	label.hide()
	
	if not Engine.editor_hint:
		visual_rect.color = Color(0, 0, 0, 0)
	
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")

func _process(_delta):
	pass # Không cần kiểm tra phím bấm nữa

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("npcs"):
		teleport_body(body)

func teleport_body(body):
	var final_pos = target_position
	if target_node_path != null and not target_node_path.is_empty():
		var target_node = get_node_or_null(target_node_path)
		if target_node != null and target_node is Node2D:
			final_pos = target_node.global_position
			
	# Dịch chuyển
	body.global_position = final_pos
	
	# Nếu là NPC, tính lại đường đi
	if body.has_method("on_teleported"):
		body.on_teleported()

func _on_body_exited(body):
	pass
