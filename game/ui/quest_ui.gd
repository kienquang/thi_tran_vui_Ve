extends CanvasLayer

onready var coins_lbl = $CoinsLabel
onready var quest_btn = $QuestBtn
onready var inv_btn = $InvBtn

onready var quest_panel = $QuestPanel
onready var quest_container = $QuestPanel/Scroll/VBox/QuestList
onready var done_container = $QuestPanel/Scroll/VBox/DoneList

onready var inv_panel = $InvPanel
onready var inv_container = $InvPanel/Scroll/VBox/InvList

var day_label: Button

func _ready():
	day_label = Button.new()
	day_label.name = "DayButton"
	day_label.add_font_override("font", _make_font(18))
	day_label.anchor_left = 1.0
	day_label.anchor_right = 1.0
	day_label.margin_left = -220
	day_label.margin_right = -20
	day_label.margin_top = 75
	day_label.margin_bottom = 105
	UIUtils.style_button(day_label)
	day_label.text = "📅 Ngày %d, %s" % [TimeManager.day, TimeManager.WEEKDAYS[TimeManager.week_day]]
	add_child(day_label)
	move_child(day_label, 0)
	day_label.connect("pressed", self, "_on_calendar_pressed")
	TimeManager.connect("day_changed", self, "_on_day_changed")
	
	_init_calendar_ui()

	var panel_tex = load("res://assets/others/resident_message_shell_clean_v2.png")
	var style = StyleBoxTexture.new()
	style.texture = panel_tex
	style.margin_left = 32
	style.margin_right = 32
	style.margin_top = 32
	style.margin_bottom = 32
	# Padding bên trong để không bị đè lên viền
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	
	quest_panel.add_stylebox_override("panel", style)
	inv_panel.add_stylebox_override("panel", style)
	
	$QuestPanel/Scroll.margin_left = 35
	$QuestPanel/Scroll.margin_top = 60
	$QuestPanel/Scroll.margin_right = -35
	$QuestPanel/Scroll.margin_bottom = -35
	
	$InvPanel/Scroll.margin_left = 35
	$InvPanel/Scroll.margin_top = 60
	$InvPanel/Scroll.margin_right = -35
	$InvPanel/Scroll.margin_bottom = -35
	
	var font_hd = _make_font(18)
	var font_btn = _make_font(16)
	
	coins_lbl.add_font_override("font", font_hd)
	coins_lbl.add_color_override("font_color", Color(1.0, 0.85, 0.1))
	coins_lbl.add_color_override("font_color_shadow", Color(0, 0, 0, 0.8))
	coins_lbl.text = "Xu: 0"
	
	var hdr_color = Color(0.2, 0.1, 0.05)
	$QuestPanel/HdrQuest.add_color_override("font_color", hdr_color)
	$QuestPanel/HdrQuest.add_font_override("font", font_hd)
	
	$QuestPanel/Scroll/VBox/HdrDone.add_color_override("font_color", hdr_color)
	$QuestPanel/Scroll/VBox/HdrDone.add_font_override("font", font_hd)
	
	$InvPanel/HdrInv.add_color_override("font_color", hdr_color)
	$InvPanel/HdrInv.add_font_override("font", font_hd)
	
	quest_btn.add_font_override("font", font_btn)
	inv_btn.add_font_override("font", font_btn)
	UIUtils.style_button(quest_btn)
	UIUtils.style_button(inv_btn)
	
	quest_panel.hide()
	inv_panel.hide()
	
	QuestManager.connect("quest_accepted", self, "_on_data_changed")
	QuestManager.connect("quest_completed", self, "_on_data_changed")
	
	quest_btn.connect("pressed", self, "_on_quest_toggle")
	inv_btn.connect("pressed", self, "_on_inv_toggle")

func _make_font(sz: int) -> DynamicFont:
	var f = DynamicFont.new()
	f.font_data = load("res://assets/ARIAL.TTF")
	f.size = sz
	return f

func _on_quest_toggle():
	if quest_panel.visible:
		quest_panel.hide()
	else:
		inv_panel.hide()
		quest_panel.show()
		_refresh_all()

func _on_inv_toggle():
	if inv_panel.visible:
		inv_panel.hide()
	else:
		quest_panel.hide()
		inv_panel.show()
		_refresh_all()

func _on_data_changed(_q):
	if quest_panel.visible or inv_panel.visible:
		_refresh_all()

func _on_day_changed(d, weekday):
	day_label.text = "📅 Ngày %d, %s" % [d, weekday]

func update_coins(amount: int):
	coins_lbl.text = "Xu: " + str(amount)

func refresh_inventory(inv: Dictionary):
	if inv_panel.visible:
		_draw_inventory(inv)

func _refresh_all():
	_draw_quests()
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player and "inventory" in player:
		_draw_inventory(player.inventory)

func _draw_quests():
	var font = _make_font(14)
	for c in quest_container.get_children():
		c.queue_free()
	for c in done_container.get_children():
		c.queue_free()
	
	$QuestPanel/HdrQuest.show()
	if not QuestManager.active_quests.empty():
		for q in QuestManager.active_quests:
			var rtl = RichTextLabel.new()
			rtl.bbcode_enabled = true
			rtl.fit_content_height = true
			rtl.rect_min_size = Vector2(240, 65)
			rtl.add_font_override("normal_font", font)
			rtl.bbcode_text = "[color=#8B4513]>> " + q["title"] + "[/color]\n[color=#333333]" + q["desc"] + "[/color]\n[color=#006400]Thưởng: " + str(q["reward_coins"]) + " xu[/color]"
			quest_container.add_child(rtl)
			
			var sep = HSeparator.new()
			sep.modulate = Color(1,1,1, 0.3)
			quest_container.add_child(sep)
	
	if QuestManager.completed_quests.empty():
		$QuestPanel/Scroll/VBox/HdrDone.hide()
	else:
		$QuestPanel/Scroll/VBox/HdrDone.show()
		for i in range(QuestManager.completed_quests.size()):
			var q = QuestManager.completed_quests[i]
			var btn = Button.new()
			btn.flat = true
			btn.align = Button.ALIGN_LEFT
			btn.add_font_override("font", font)
			btn.text = "[Xong] " + q["title"]
			# Custom color for completed quests
			btn.add_color_override("font_color", Color(0.3, 0.3, 0.3))
			btn.add_color_override("font_color_hover", Color(0.8, 0.2, 0.2)) # Hover red to indicate deletion
			btn.connect("pressed", self, "_on_remove_done_quest", [i])
			
			# Dùng RichTextLabel overlay để có nét gạch ngang (strikethrough)
			var rtl = RichTextLabel.new()
			rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rtl.bbcode_enabled = true
			rtl.bbcode_text = "[s][color=#555555][Xong] " + q["title"] + "[/color][/s]"
			rtl.add_font_override("normal_font", font)
			rtl.anchor_right = 1.0
			rtl.anchor_bottom = 1.0
			# Thay thế nội dung chữ của Button
			btn.text = "" 
			btn.add_child(rtl)
			
			btn.rect_min_size = Vector2(240, 24)
			done_container.add_child(btn)

func _on_remove_done_quest(index: int):
	if index >= 0 and index < QuestManager.completed_quests.size():
		QuestManager.completed_quests.remove(index)
		_draw_quests()

func _draw_inventory(inv: Dictionary):
	var font = _make_font(14)
	for c in inv_container.get_children():
		c.queue_free()
	
	$InvPanel/HdrInv.show()
	if inv.empty():
		return
	
	for item_name in inv.keys():
		if inv[item_name] <= 0:
			continue
		var lbl = Label.new()
		lbl.add_font_override("font", font)
		lbl.text = "- " + item_name + ": " + str(inv[item_name])
		lbl.add_color_override("font_color", Color(0.2, 0.2, 0.2))
		inv_container.add_child(lbl)

var calendar_panel: Control
var event_input: LineEdit
var day_spinbox: SpinBox

func _init_calendar_ui():
	calendar_panel = Control.new()
	calendar_panel.name = "CalendarPanel"
	calendar_panel.set_anchors_preset(Control.PRESET_WIDE)
	calendar_panel.hide()
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_WIDE)
	calendar_panel.add_child(center)
	
	var bg = Panel.new()
	bg.rect_min_size = Vector2(300, 200)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.15, 0.2)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	bg.add_stylebox_override("panel", sb)
	center.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_WIDE)
	vbox.margin_left = 20
	vbox.margin_top = 20
	vbox.margin_right = -20
	vbox.margin_bottom = -20
	vbox.add_constant_override("separation", 15)
	bg.add_child(vbox)
	
	var title = Label.new()
	title.text = "Tạo Sự Kiện Lịch"
	title.align = Label.ALIGN_CENTER
	title.add_font_override("font", _make_font(18))
	vbox.add_child(title)
	
	var hbox_day = HBoxContainer.new()
	var lbl_day = Label.new()
	lbl_day.text = "Ngày:"
	lbl_day.add_font_override("font", _make_font(14))
	hbox_day.add_child(lbl_day)
	
	day_spinbox = SpinBox.new()
	day_spinbox.min_value = 1
	day_spinbox.max_value = 999
	day_spinbox.value = TimeManager.day
	hbox_day.add_child(day_spinbox)
	vbox.add_child(hbox_day)
	
	var hbox_evt = HBoxContainer.new()
	var lbl_evt = Label.new()
	lbl_evt.text = "Sự kiện:"
	lbl_evt.add_font_override("font", _make_font(14))
	hbox_evt.add_child(lbl_evt)
	
	event_input = LineEdit.new()
	event_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_input.placeholder_text = "Lễ hội, chợ phiên, sinh nhật..."
	event_input.add_font_override("font", _make_font(14))
	hbox_evt.add_child(event_input)
	vbox.add_child(hbox_evt)
	
	var hbox_btn = HBoxContainer.new()
	hbox_btn.alignment = BoxContainer.ALIGN_CENTER
	hbox_btn.add_constant_override("separation", 20)
	
	var btn_save = Button.new()
	btn_save.text = "Lưu"
	btn_save.rect_min_size = Vector2(80, 35)
	btn_save.add_font_override("font", _make_font(14))
	UIUtils.style_button(btn_save)
	btn_save.connect("pressed", self, "_on_save_event", [btn_save])
	hbox_btn.add_child(btn_save)
	
	var btn_close = Button.new()
	btn_close.text = "Đóng"
	btn_close.rect_min_size = Vector2(80, 35)
	btn_close.add_font_override("font", _make_font(14))
	UIUtils.style_button(btn_close)
	btn_close.connect("pressed", self, "_on_close_calendar")
	hbox_btn.add_child(btn_close)
	
	vbox.add_child(hbox_btn)
	add_child(calendar_panel)

func _on_calendar_pressed():
	day_spinbox.value = TimeManager.day
	event_input.text = TimeManager.get_event_for_day(TimeManager.day)
	calendar_panel.show()

func _on_save_event(btn_save: Button):
	var d = int(day_spinbox.value)
	var txt = event_input.text.strip_edges()
	TimeManager.set_event_for_day(d, txt)
	
	# Lưu thẳng vào game luôn
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()
	
	# Hiệu ứng đổi chữ nút
	if btn_save:
		btn_save.text = "Đã lưu!"
		yield(get_tree().create_timer(0.5), "timeout")
		if btn_save:
			btn_save.text = "Lưu"
			
	calendar_panel.hide()

func _on_close_calendar():
	calendar_panel.hide()
