extends CanvasLayer

func _ready():
	pass

# Hàm chung để giả lập tín hiệu cho InputEventAction
func trigger_input_action(action_name: String, is_pressed: bool):
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = is_pressed
	Input.parse_input_event(event)

# Giả lập input cho các phím di chuyển 
func simulate_dpad_input(dir: Vector2):
	# Trục X
	if dir.x > 0.5:
		trigger_input_action("ui_right", true)
		trigger_input_action("ui_left", false)
	elif dir.x < -0.5:
		trigger_input_action("ui_left", true)
		trigger_input_action("ui_right", false)
	else:
		trigger_input_action("ui_right", false)
		trigger_input_action("ui_left", false)
		
	# Trục Y
	if dir.y > 0.5:
		trigger_input_action("ui_down", true)
		trigger_input_action("ui_up", false)
	elif dir.y < -0.5:
		trigger_input_action("ui_up", true)
		trigger_input_action("ui_down", false)
	else:
		trigger_input_action("ui_down", false)
		trigger_input_action("ui_up", false)

# Có thể kết nối hàm này với tín hiệu button_down/button_up của nút ảo (ActionButton)
# Lưu ý: Cần mapping action "interact" tương ứng với phím E trong Project Settings -> Input Map
func on_action_button_pressed():
	trigger_input_action("interact", true)

func on_action_button_released():
	trigger_input_action("interact", false)
