extends CanvasLayer

onready var panel = $Panel
onready var btn_toggle = $ToggleBtn
onready var coins_lbl = $CoinsLabel
onready var quest_container = $Panel/Scroll/VBox/QuestList
onready var done_container = $Panel/Scroll/VBox/DoneList
onready var inv_container = $Panel/Scroll/VBox/InvList

func _ready():
	var font = _make_font(14)
	
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
