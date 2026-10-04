extends CanvasLayer

onready var panel = $Panel
onready var btn_toggle = $ToggleBtn
onready var coins_lbl = $CoinsLabel
onready var quest_container = $Panel/Scroll/VBox/QuestList
onready var done_container = $Panel/Scroll/VBox/DoneList
onready var inv_container = $Panel/Scroll/VBox/InvList
onready var day_label = Label.new()

func _ready():
	var font = _make_font(14)
	
	day_label = Button.new()
	day_label.name = "DayButton"
	day_label.add_font_override("font", _make_font(18))
	day_label.align = Label.ALIGN_RIGHT
	day_label.anchor_left = 1.0
	day_label.anchor_right = 1.0
	day_label.margin_left = -250
	day_label.margin_right = -20
	day_label.margin_top = 75
	day_label.margin_bottom = 105
	UIUtils.style_button(day_label)
	day_label.text = "📅 Ngày %d, %s" % [TimeManager.day, TimeManager.WEEKDAYS[TimeManager.week_day]]
	add_child(day_label)
	day_label.connect("pressed", self, "_on_calendar_pressed")
	TimeManager.connect("day_changed", self, "_on_day_changed")
	
	_init_calendar_ui()

	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.10, 0.97)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_stylebox_override("panel", style)
	
	var font_hd = _make_font(18)
	
	coins_lbl.add_font_override("font", font_hd)
	coins_lbl.add_color_override("font_color", Color(1.0, 0.85, 0.1))
	coins_lbl.add_color_override("font_color_shadow", Color(0, 0, 0, 0.8))
	coins_lbl.text = "Xu: 0"
	
	btn_toggle.add_font_override("font", font)
	UIUtils.style_button(btn_toggle)
	panel.hide()
	
	QuestManager.connect("quest_accepted", self, "_on_data_changed")
	QuestManager.connect("quest_completed", self, "_on_data_changed")
	btn_toggle.connect("pressed", self, "_on_toggle")

func _make_font(sz: int) -> DynamicFont:
	var f = DynamicFont.new()
	f.font_data = load("res://assets/ARIAL.TTF")
	f.size = sz
	f.use_filter = true
	return f

func _on_toggle():
	panel.visible = not panel.visible
	if panel.visible:
		_refresh_all()

func _on_data_changed(_q):
	if panel.visible:
		_refresh_all()

func _on_day_changed(d, weekday):
	day_label.text = "📅 Ngày %d, %s" % [d, weekday]

func update_coins(amount: int):
	coins_lbl.text = "Xu: " + str(amount)

func refresh_inventory(inv: Dictionary):
	if panel.visible:
		_draw_inventory(inv)

func _refresh_all():
	_draw_quests()
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player and "inventory" in player:
		_draw_inventory(player.inventory)

func _draw_quests():
	var font = _make_font(13)
	for c in quest_container.get_children():
		c.queue_free()
	for c in done_container.get_children():
		c.queue_free()
	
	if QuestManager.active_quests.empty():
		var lbl = Label.new()
		lbl.add_font_override("font", font)
		lbl.text = "(Chua co nhiem vu)"
		lbl.add_color_override("font_color", Color(0.5, 0.5, 0.5))
		quest_container.add_child(lbl)
	else:
		for q in QuestManager.active_quests:
			var rtl = RichTextLabel.new()
			rtl.bbcode_enabled = true
			rtl.rect_min_size = Vector2(260, 65)
			rtl.add_font_override("normal_font", font)
			rtl.bbcode_text = "[color=#FFD700]>> " + q["title"] + "[/color]\n[color=#CCCCCC]" + q["desc"] + "[/color]\n[color=#AAFFAA]Thuong: " + str(q["reward_coins"]) + " xu[/color]"
			quest_container.add_child(rtl)
			quest_container.add_child(HSeparator.new())
	
	var start = max(0, QuestManager.completed_quests.size() - 5)
	for i in range(start, QuestManager.completed_quests.size()):
		var q = QuestManager.completed_quests[i]
		var lbl = Label.new()
		lbl.add_font_override("font", font)
		lbl.text = "[Xong] " + q["title"]
		lbl.add_color_override("font_color", Color(0.5, 0.9, 0.5))
		done_container.add_child(lbl)

func _draw_inventory(inv: Dictionary):
	var font = _make_font(13)
	for c in inv_container.get_children():
		c.queue_free()
	
	if inv.empty():
		var lbl = Label.new()
		lbl.add_font_override("font", font)
		lbl.text = "(Tui trong)"
		lbl.add_color_override("font_color", Color(0.5, 0.5, 0.5))
		inv_container.add_child(lbl)
		return
	
	for item_name in inv.keys():
		if inv[item_name] <= 0:
			continue
		var lbl = Label.new()
		lbl.add_font_override("font", font)
		lbl.text = item_name + "  x" + str(inv[item_name])
		lbl.add_color_override("font_color", Color(1, 1, 0.8))
		inv_container.add_child(lbl)

var calendar_panel: PanelContainer
var event_input: LineEdit
var day_spinbox: SpinBox

func _init_calendar_ui():
	calendar_panel = PanelContainer.new()
	calendar_panel.name = "CalendarPanel"
	calendar_panel.rect_size = Vector2(300, 200)
	calendar_panel.anchor_left = 0.5
	calendar_panel.anchor_top = 0.5
	calendar_panel.anchor_right = 0.5
	calendar_panel.anchor_bottom = 0.5
	calendar_panel.margin_left = -150
	calendar_panel.margin_top = -100
	calendar_panel.margin_right = 150
	calendar_panel.margin_bottom = 100
	calendar_panel.hide()
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	calendar_panel.add_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGN_CENTER
	vbox.add_constant_override("separation", 10)
	calendar_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Tạo Sự Kiện Lịch"
	title.align = Label.ALIGN_CENTER
	title.add_font_override("font", _make_font(18))
	vbox.add_child(title)
	
	var hbox1 = HBoxContainer.new()
	var lbl_day = Label.new()
	lbl_day.text = "Ngày:"
	lbl_day.add_font_override("font", _make_font(14))
	day_spinbox = SpinBox.new()
	day_spinbox.min_value = 1
	day_spinbox.max_value = 999
	day_spinbox.value = TimeManager.day + 1
	hbox1.add_child(lbl_day)
	hbox1.add_child(day_spinbox)
	vbox.add_child(hbox1)
	
	var hbox2 = HBoxContainer.new()
	var lbl_event = Label.new()
	lbl_event.text = "Sự kiện:"
	lbl_event.add_font_override("font", _make_font(14))
	event_input = LineEdit.new()
	event_input.placeholder_text = "Lễ hội, chợ phiên, sinh nhật..."
	event_input.rect_min_size = Vector2(200, 30)
	event_input.add_font_override("font", _make_font(14))
	hbox2.add_child(lbl_event)
	hbox2.add_child(event_input)
	vbox.add_child(hbox2)
	
	var hbox3 = HBoxContainer.new()
	hbox3.alignment = BoxContainer.ALIGN_CENTER
	var btn_save = Button.new()
	btn_save.text = "Lưu"
	btn_save.add_font_override("font", _make_font(14))
	btn_save.connect("pressed", self, "_on_save_event")
	UIUtils.style_button(btn_save)
	var btn_close = Button.new()
	btn_close.text = "Đóng"
	btn_close.add_font_override("font", _make_font(14))
	btn_close.connect("pressed", self, "_on_calendar_pressed")
	UIUtils.style_button(btn_close)
	hbox3.add_child(btn_save)
	hbox3.add_child(btn_close)
	vbox.add_child(hbox3)
	
	add_child(calendar_panel)

func _on_calendar_pressed():
	calendar_panel.visible = not calendar_panel.visible
	if calendar_panel.visible:
		day_spinbox.value = TimeManager.day + 1
		event_input.text = ""

func _on_save_event():
	var d = int(day_spinbox.value)
	var ev = event_input.text.strip_edges()
	TimeManager.set_event_for_day(d, ev)
	calendar_panel.hide()
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player:
		var log_node = get_node_or_null("/root/WorldLog")
		if log_node:
			log_node.add_entry("Bạn đã lên lịch: " + ev + " vào Ngày " + str(d))
