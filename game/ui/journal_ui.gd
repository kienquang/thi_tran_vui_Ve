extends CanvasLayer

onready var panel = $Panel
onready var log_label = $Panel/LogLabel

func _ready():
	var font = DynamicFont.new()
	font.font_data = load("res://assets/ARIAL.TTF")
	font.size = 14
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_stylebox_override("panel", style)
	
	$Panel/Title.add_font_override("font", font)
	log_label.add_font_override("normal_font", font)
	
	panel.hide()
	WorldLog.connect("log_added", self, "_on_log_added")
	update_log_display()
	
	var btn_toggle = Button.new()
	btn_toggle.text = "Nhat Ky"
	btn_toggle.add_font_override("font", font)
	btn_toggle.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn_toggle.rect_position = Vector2(10, -38)
	btn_toggle.rect_min_size = Vector2(110, 32)
	UIUtils.style_button(btn_toggle, Color(0.25, 0.38, 0.60))
	btn_toggle.connect("pressed", self, "_on_toggle_btn_pressed")
	add_child(btn_toggle)

func _on_toggle_btn_pressed():
	panel.visible = not panel.visible
	if panel.visible:
		update_log_display()

func _input(event):
	# Nhấn Tab hoặc phím J để bật/tắt Nhật ký
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_TAB or event.scancode == KEY_J:
			_on_toggle_btn_pressed()

func _on_log_added(_new_log):
	if panel.visible:
		update_log_display()

func update_log_display():
	var logs = WorldLog.global_logs
	var text = ""
	for i in range(logs.size() - 1, -1, -1): # Đảo ngược để tin mới nhất lên đầu
		text += logs[i] + "\n"
	log_label.text = text
