extends Node2D

export var light_color: Color = Color(1.0, 0.88, 0.58) # Ánh sáng vàng cam ấm áp
export var light_scale: float = 3.5 # Kích thước vùng sáng tròn (~400px)
export var max_energy: float = 1.15 # Độ sáng cực đại ban đêm

onready var light: Light2D = $Light2D
onready var editor_preview: ColorRect = $EditorPreview

var _light_tex: ImageTexture = null

var current_energy: float = 0.0
var flicker_offset: float = 0.0

func _ready():
	# Ẩn ô đánh dấu màu vàng khi vào trong game thực tế
	if editor_preview:
		editor_preview.hide()
		
	_light_tex = _create_radial_texture(64)
		
	if light:
		light.texture = _light_tex
		light.texture_scale = light_scale
		light.color = light_color
		light.energy = 0.0
		light.shadow_enabled = false
		light.show()
		
	flicker_offset = randf() * 100.0

func _process(delta):
	if light == null:
		return
		
	var h = TimeManager.game_hour
	var m = TimeManager.game_minute
	var target_energy: float = 0.0
	
	if h >= 19 or h < 5:
		# Đêm muộn: Bật sáng
		target_energy = max_energy
	elif h >= 17 and h < 19:
		# Hoàng hôn: Sáng dần lên
		var progress = ((h - 17) * 60.0 + m) / 120.0
		target_energy = progress * max_energy
	elif h >= 5 and h < 6:
		# Bình minh: Mờ dần và tắt hẳn
		var progress = 1.0 - (m / 60.0)
		target_energy = progress * max_energy
	else:
		# Ban ngày: Tắt, trừ khi trời bão lớn
		if TimeManager.current_weather == "STORM":
			target_energy = max_energy * 0.7
		else:
			target_energy = 0.0
			
	current_energy = lerp(current_energy, target_energy, delta * 2.0)
	
	if current_energy > 0.01:
		var flicker = sin(OS.get_ticks_msec() * 0.005 + flicker_offset) * 0.03
		light.energy = max(0.0, current_energy + flicker)
		light.visible = true
	else:
		light.energy = 0.0
		light.visible = false

func _create_radial_texture(size: int) -> ImageTexture:
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	img.lock()
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist >= radius:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
			else:
				var t = dist / radius
				var alpha = cos(t * (PI * 0.5))
				alpha = alpha * alpha
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	img.unlock()
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex
