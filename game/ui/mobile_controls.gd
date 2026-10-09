extends CanvasLayer

var joystick_active = false
var joystick_center = Vector2.ZERO
var joystick_vector = Vector2.ZERO
var joystick_radius = 50.0

var left_area: Control
var joy_bg: Panel
var joy_handle: Panel
var btn_interact: Button

func _ready():
	self.layer = 0 # Nằm dưới các nút UI khác (Quest, Inventory...)
	
	left_area = Control.new()
	left_area.set_anchors_preset(Control.PRESET_WIDE)
	left_area.anchor_right = 0.5
	left_area.margin_right = 0
	left_area.connect("gui_input", self, "_on_left_area_input")
	add_child(left_area)
	
	joy_bg = Panel.new()
	joy_bg.rect_size = Vector2(100, 100)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.4)
	bg_style.corner_radius_top_left = 50
	bg_style.corner_radius_top_right = 50
	bg_style.corner_radius_bottom_left = 50
	bg_style.corner_radius_bottom_right = 50
	joy_bg.add_stylebox_override("panel", bg_style)
	joy_bg.hide()
	add_child(joy_bg)
	
	joy_handle = Panel.new()
	joy_handle.rect_size = Vector2(40, 40)
	var handle_style = StyleBoxFlat.new()
	handle_style.bg_color = Color(1, 1, 1, 0.7)
	handle_style.corner_radius_top_left = 20
	handle_style.corner_radius_top_right = 20
	handle_style.corner_radius_bottom_left = 20
	handle_style.corner_radius_bottom_right = 20
	joy_handle.add_stylebox_override("panel", handle_style)
	joy_bg.add_child(joy_handle)
	
	btn_interact = Button.new()
	btn_interact.text = "E"
	
	var btn_font = DynamicFont.new()
	btn_font.font_data = load("res://assets/ARIAL.TTF")
	btn_font.size = 36
	btn_interact.add_font_override("font", btn_font)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.5, 0.5, 0.5, 0.5) # xám mờ nhạt
	btn_style.corner_radius_top_left = 40
	btn_style.corner_radius_top_right = 40
	btn_style.corner_radius_bottom_left = 40
	btn_style.corner_radius_bottom_right = 40
	
	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.3, 0.3, 0.3, 0.7)
	
	btn_interact.add_stylebox_override("normal", btn_style)
	btn_interact.add_stylebox_override("hover", btn_style)
	btn_interact.add_stylebox_override("pressed", btn_pressed)
	btn_interact.add_stylebox_override("focus", StyleBoxEmpty.new())
	btn_interact.add_color_override("font_color", Color(1, 1, 1, 0.9))
	
	btn_interact.focus_mode = Control.FOCUS_NONE
	
	btn_interact.rect_size = Vector2(80, 80)
	btn_interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_interact.margin_left = -250
	btn_interact.margin_top = -120
	btn_interact.margin_right = -170
	btn_interact.margin_bottom = -40
	
	btn_interact.connect("button_down", self, "_on_interact_down")
	btn_interact.connect("button_up", self, "_on_interact_up")
	add_child(btn_interact)

func _on_left_area_input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var is_pressed = event.pressed
		var ev_pos = event.position
		
		if event is InputEventMouseButton and event.button_index != BUTTON_LEFT:
			return
			
		if is_pressed:
			joystick_active = true
			joystick_center = ev_pos
			joy_bg.rect_global_position = joystick_center - joy_bg.rect_size / 2
			joy_bg.show()
			joy_handle.rect_position = joy_bg.rect_size / 2 - joy_handle.rect_size / 2
		else:
			joystick_active = false
			joy_bg.hide()
			_reset_joystick()
			
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if joystick_active:
			var offset = event.position - joystick_center
			if offset.length() > joystick_radius:
				offset = offset.normalized() * joystick_radius
			joy_handle.rect_position = (joy_bg.rect_size / 2) + offset - (joy_handle.rect_size / 2)
			
			joystick_vector = offset / joystick_radius
			_update_actions()

var last_actions = {"ui_up": false, "ui_down": false, "ui_left": false, "ui_right": false}

func _fire_action(action: String, pressed: bool):
	if last_actions[action] == pressed:
		return
	last_actions[action] = pressed
	
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _update_actions():
	_fire_action("ui_up", joystick_vector.y < -0.3)
	_fire_action("ui_down", joystick_vector.y > 0.3)
	_fire_action("ui_left", joystick_vector.x < -0.3)
	_fire_action("ui_right", joystick_vector.x > 0.3)

func _reset_joystick():
	joystick_vector = Vector2.ZERO
	_update_actions()

func _on_interact_down():
	var ev = InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)

func _on_interact_up():
	var ev = InputEventAction.new()
	ev.action = "interact"
	ev.pressed = false
	Input.parse_input_event(ev)
