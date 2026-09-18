tool
extends StaticBody2D

func _ready():
	if not Engine.editor_hint:
		if has_node("Polygon2D"):
			# Tàng hình khi chơi game thật
			$Polygon2D.color = Color(0, 0, 0, 0)

func _process(_delta):
	# Tự động đồng bộ hình ảnh màu đỏ với khung va chạm đa giác khi đang ở màn hình Editor
	if Engine.editor_hint:
		if has_node("CollisionPolygon2D") and has_node("Polygon2D"):
			$Polygon2D.polygon = $CollisionPolygon2D.polygon
			$Polygon2D.color = Color(1, 0, 0, 0.4)
