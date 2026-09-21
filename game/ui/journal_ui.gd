extends CanvasLayer

onready var panel = $Panel
onready var log_label = $Panel/LogLabel

func _ready():
	var font = DynamicFont.new()
	font.font_data = load("res://assets/ARIAL.TTF")
	font.size = 14
	
	$Panel/Title.add_font_override("font", font)
	log_label.add_font_override("normal_font", font)
	
	panel.hide()
	WorldLog.connect("log_added", self, "_on_log_added")
	update_log_display()

func _input(event):
	# Nhấn Tab hoặc phím J để bật/tắt Nhật ký
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_TAB or event.scancode == KEY_J:
			panel.visible = not panel.visible
			if panel.visible:
				update_log_display()

func _on_log_added(_new_log):
	if panel.visible:
		update_log_display()

func update_log_display():
	var logs = WorldLog.global_logs
	var text = ""
	for i in range(logs.size() - 1, -1, -1): # Đảo ngược để tin mới nhất lên đầu
		text += logs[i] + "\n"
	log_label.text = text
