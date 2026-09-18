tool
extends ColorRect

func _ready():
	connect("item_rect_changed", self, "_on_rect_changed")
	
	# Tự động cấp một hình khối va chạm độc lập cho mỗi khối
	if has_node("StaticBody2D/CollisionShape2D"):
		var shape_node = $StaticBody2D/CollisionShape2D
		if shape_node.shape == null or not shape_node.shape is RectangleShape2D:
			shape_node.shape = RectangleShape2D.new()
		else:
			shape_node.shape = shape_node.shape.duplicate()
			
	_on_rect_changed()
	
	# Khi chơi game thật, tự động làm khối đỏ tàng hình
	if not Engine.editor_hint:
		color = Color(0, 0, 0, 0)

# Hàm này tự động gọi khi bạn kéo viền khối vuông trên màn hình
func _on_rect_changed():
	if has_node("StaticBody2D/CollisionShape2D"):
		var shape_node = $StaticBody2D/CollisionShape2D
		if shape_node.shape is RectangleShape2D:
			# Tự động khớp kích thước khối va chạm với kích thước hình chữ nhật
			shape_node.shape.extents = rect_size / 2.0
			shape_node.position = rect_size / 2.0
