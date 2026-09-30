extends Node
class_name UIUtils

static func style_button(btn: Button, base_color: Color = Color(0.15, 0.15, 0.17)):
	# Bỏ qua màu mè, dùng tông màu tối giản, chuyên nghiệp
	var c_normal = Color(0.12, 0.12, 0.14, 0.9)
	var c_hover = Color(0.2, 0.2, 0.22, 0.9)
	var c_pressed = Color(0.08, 0.08, 0.1, 0.9)
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = c_normal
	sb_normal.corner_radius_top_left = 4
	sb_normal.corner_radius_top_right = 4
	sb_normal.corner_radius_bottom_left = 4
	sb_normal.corner_radius_bottom_right = 4
	sb_normal.border_width_left = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = Color(0.3, 0.3, 0.35, 0.5)
	sb_normal.content_margin_left = 10
	sb_normal.content_margin_right = 10
	sb_normal.content_margin_top = 5
	sb_normal.content_margin_bottom = 5
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = c_hover
	sb_hover.border_color = Color(0.5, 0.5, 0.55, 0.8)
	
	var sb_pressed = sb_normal.duplicate()
	sb_pressed.bg_color = c_pressed
	sb_pressed.border_color = Color(0.1, 0.1, 0.1, 0.5)
	
	var sb_empty = StyleBoxEmpty.new()
	
	btn.add_stylebox_override("normal", sb_normal)
	btn.add_stylebox_override("hover", sb_hover)
	btn.add_stylebox_override("pressed", sb_pressed)
	btn.add_stylebox_override("focus", sb_empty)
	btn.add_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_color_override("font_color_hover", Color(1.0, 1.0, 1.0))
	btn.add_color_override("font_color_pressed", Color(0.7, 0.7, 0.7))

static func style_option_button(opt: OptionButton):
	style_button(opt)
	
	var popup = opt.get_popup()
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.12, 0.12, 0.14, 0.95)
	panel.corner_radius_bottom_left = 4
	panel.corner_radius_bottom_right = 4
	panel.border_width_left = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = Color(0.3, 0.3, 0.35, 0.5)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.2, 0.2, 0.22, 1.0)
	
	popup.add_stylebox_override("panel", panel)
	popup.add_stylebox_override("hover", hover)
	popup.add_color_override("font_color", Color(0.9, 0.9, 0.9))
	popup.add_color_override("font_color_hover", Color(1.0, 1.0, 1.0))
	
	if opt.has_font_override("font"):
		popup.add_font_override("font", opt.get_font("font"))
