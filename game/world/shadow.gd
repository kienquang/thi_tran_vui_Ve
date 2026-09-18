tool
extends Node2D

export var radius_x = 14.0
export var radius_y = 6.0
export var shadow_color = Color(0, 0, 0, 0.4)

func _draw():
	# Vẽ một hình elip (bóng tròn dẹt) dưới chân nhân vật
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, radius_y / radius_x))
	draw_circle(Vector2.ZERO, radius_x, shadow_color)

func _process(_delta):
	if Engine.editor_hint:
		update()
