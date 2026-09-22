extends CPUParticles2D

var weather_modulate = Color(1, 1, 1, 1)

func _ready():
	emitting = false
	TimeManager.connect("weather_changed", self, "_on_weather_changed")

func _on_weather_changed(weather_type: String):
	if weather_type == "SUNNY" or weather_type == "FOG":
		emitting = false
	elif weather_type == "RAIN" or weather_type == "STORM":
		emitting = true
		amount = 400 if weather_type == "RAIN" else 1000
		direction = Vector2(0.1, 1) if weather_type == "RAIN" else Vector2(0.8, 1)
		initial_velocity = 400.0 if weather_type == "RAIN" else 800.0
		color = Color(0.5, 0.7, 1, 0.6)
		# Mưa dạng sọc
		var img = Image.new()
		img.create(2, 25, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.7, 0.85, 1.0, 0.8))
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		self.texture = tex
		self.scale_amount = 1.0
	elif weather_type == "SNOW":
		emitting = true
		amount = 300
		direction = Vector2(0.2, 1)
		initial_velocity = 100.0
		color = Color(1, 1, 1, 0.8)
		# Tuyết dạng hạt tròn
		var img = Image.new()
		img.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0.8))
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		self.texture = tex
		self.scale_amount = 2.0

func _process(_delta):
	if not emitting: return
	var camera = get_parent().get_node_or_null("Camera2D")
	if camera:
		# Bám sát vị trí của camera thay vì vị trí của người chơi
		global_position = camera.global_position + Vector2(0, -300 * camera.zoom.y)
		# Scale toàn bộ hiệu ứng theo độ zoom để mưa/tuyết phủ kín màn hình và không bị thưa đi
		scale = camera.zoom

