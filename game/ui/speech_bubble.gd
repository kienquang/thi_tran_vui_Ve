extends PanelContainer

# Sử dụng onready var theo chuẩn Godot 3.x (không có @)
# Giả định cấu trúc Scene có một Node con là Label tên "Label"
onready var label = $Label

func _ready():
	var font = DynamicFont.new()
	font.font_data = load("res://assets/ARIAL.TTF")
	font.size = 14
	label.add_font_override("font", font)
	
	# Ẩn bong bóng thoại khi mới khởi tạo
	hide()

func show_text(message: String):
	# Cập nhật nội dung cho Label con
	label.text = message
	show()
	
	# Chờ 4 giây bằng cú pháp yield của Godot 3.x
	yield(get_tree().create_timer(4.0), "timeout")
	
	# Tự động ẩn đi sau khi hết 4 giây
	hide()
