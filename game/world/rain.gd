extends CPUParticles2D

func _ready():
	# Tự động tạo ảnh hạt mưa dạng sọc dài bằng code để mưa trông chân thực
	var img = Image.new()
	img.create(2, 25, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.7, 0.85, 1.0, 0.8)) # Màu xanh lơ trong suốt
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	self.texture = tex
	
	self.scale_amount = 1.0 # Trả lại scale gốc vì texture đã dài sẵn
	
	emitting = false
	TimeManager.connect("weather_changed", self, "_on_weather_changed")

func _on_weather_changed(is_raining):
	emitting = is_raining
