extends Node
class_name UIUtils

static func style_button(btn: Button, base_color: Color = Color(1, 1, 1)):
	var tex = load("res://assets/others/secondary_loading_b.png")
	if not tex:
		return # Nếu không load được asset, bỏ qua
		
	var sb_normal = StyleBoxTexture.new()
	sb_normal.texture = tex
	# Chỉnh margin để content không bị đè lên viền nút
	sb_normal.margin_left = 20
	sb_normal.margin_right = 20
	sb_normal.margin_top = 10
	sb_normal.margin_bottom = 10
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.modulate_color = Color(1.2, 1.2, 1.2) # Sáng lên khi hover
	
	var sb_pressed = sb_normal.duplicate()
	sb_pressed.modulate_color = Color(0.8, 0.8, 0.8) # Tối đi khi ấn
	
	var sb_empty = StyleBoxEmpty.new()
	
	btn.add_stylebox_override("normal", sb_normal)
	btn.add_stylebox_override("hover", sb_hover)
	btn.add_stylebox_override("pressed", sb_pressed)
	btn.add_stylebox_override("focus", sb_empty)
	
	# Đổi màu chữ tối cho hợp với nền asset gỗ/nhạt
	btn.add_color_override("font_color", Color(0.2, 0.1, 0.05))
	btn.add_color_override("font_color_hover", Color(0.1, 0.05, 0.0))
	btn.add_color_override("font_color_pressed", Color(0.1, 0.05, 0.0))
	btn.add_color_override("font_color_focus", Color(0.2, 0.1, 0.05))
	btn.add_color_override("font_color_disabled", Color(0.3, 0.2, 0.15))
	
static func style_button_flat(btn: Button, base_color: Color = Color(0.15, 0.15, 0.17)):
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
	
	var panel_tex = load("res://assets/others/resident_message_shell_clean_v2.png")
	var panel
	if panel_tex:
		panel = StyleBoxTexture.new()
		panel.texture = panel_tex
		panel.margin_left = 12
		panel.margin_right = 12
		panel.margin_top = 12
		panel.margin_bottom = 12
	else:
		panel = StyleBoxFlat.new()
		panel.bg_color = Color(0.12, 0.12, 0.14, 0.95)
		
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.3, 0.2, 0.1, 0.5)
	
	popup.add_stylebox_override("panel", panel)
	popup.add_stylebox_override("hover", hover)
	popup.add_color_override("font_color", Color(0.2, 0.1, 0.05))
	popup.add_color_override("font_color_hover", Color(0.1, 0.05, 0.0))
	
	opt.add_color_override("font_color", Color(0.2, 0.1, 0.05))
	opt.add_color_override("font_color_hover", Color(0.1, 0.05, 0.0))
	opt.add_color_override("font_color_pressed", Color(0.1, 0.05, 0.0))
	opt.add_color_override("font_color_focus", Color(0.2, 0.1, 0.05))
	opt.add_color_override("font_color_disabled", Color(0.2, 0.1, 0.05))
	
	if opt.has_font_override("font"):
		popup.add_font_override("font", opt.get_font("font"))
