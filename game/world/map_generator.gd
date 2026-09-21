extends TileMap

var astar = AStar2D.new()
var grid_size = 64.0
var map_width = 4800
var map_height = 3600
var cols = 0
var rows = 0

var town_locations = {
	"spawn_player": Vector2(3000, 2000),
	"park_center": Vector2(3000, 2300),
	"town_square": Vector2(2959, 1843),
	"cafe_entrance": { "door_pos": Vector2(3200, 2000), "final_pos": Vector2(10000, 10000) },
	"mayor_house":   { "door_pos": Vector2(1403, 1759), "final_pos": Vector2(5224, -218) },
	"clinic":        { "door_pos": Vector2(1831, 1506), "final_pos": Vector2(9223, 4147) },
	"workshop":      { "door_pos": Vector2(1696, 2109), "final_pos": Vector2(9189, 2498) },
	"town_hall":     { "door_pos": Vector2(2745, 792),  "final_pos": Vector2(11133, 4245) },
	"library":       { "door_pos": Vector2(1677, 548),  "final_pos": Vector2(10997, 923) },
	"home_a":        { "door_pos": Vector2(903, 2126),  "final_pos": Vector2(9218, 6136) },
	"market":        { "door_pos": Vector2(1892, 2694), "final_pos": Vector2(9134, 876) },
	"dining_hall":   { "door_pos": Vector2(4350, 1680), "final_pos": Vector2(7319, 885) },
	"dock":          { "door_pos": Vector2(3669, 1791), "final_pos": Vector2(11036, 2583) }
}

func _ready():
	yield(get_tree(), "physics_frame")
	build_astar_grid()
	create_house_labels()

func create_house_labels():
	var font = DynamicFont.new()
	font.font_data = load("res://assets/ARIAL.TTF")
	font.size = 28 # Chữ to và rõ
	font.use_filter = true
	font.outline_size = 2
	font.outline_color = Color(0, 0, 0, 1) # Viền đen cực đậm
	
	# BẠN CÓ THỂ TỰ SỬA TÊN HIỂN THỊ TẠI ĐÂY
	var location_names_vn = {
		"cafe_entrance": "Cafe",
		"mayor_house": "Mayor House",
		"clinic": "Clinic",
		"workshop": "Workshop",
		"town_hall": "Town Hall",
		"library": "Library",
		"home_a": "Home A",
		"market": "Market",
		"dining_hall": "Dining Hall",
		"dock": "Dock"
	}
	
	for key in town_locations.keys():
		var data = town_locations[key]
		if typeof(data) == TYPE_DICTIONARY and data.has("door_pos") and location_names_vn.has(key):
			var pos = data["door_pos"]
			var lbl = Label.new()
			lbl.text = location_names_vn[key]
			lbl.add_font_override("font", font)
			lbl.align = Label.ALIGN_CENTER
			lbl.valign = Label.ALIGN_CENTER
			
			lbl.rect_min_size = Vector2(240, 35)
			# Đặt nhãn nổi lên trên cửa khoảng 60 pixel
			lbl.rect_position = pos + Vector2(-120, -70)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.4)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			lbl.add_stylebox_override("normal", style)
			
			lbl.add_color_override("font_color", Color(1, 1, 1))
			
			# Nâng z_index để chữ luôn đè lên mái nhà (dùng Node2D wrapper)
			var z_wrapper = Node2D.new()
			z_wrapper.z_index = 100
			z_wrapper.position = Vector2(0, 0)
			z_wrapper.add_child(lbl)
			add_child(z_wrapper)


func find_node_by_name(parent: Node, node_name: String) -> Node:
	for child in parent.get_children():
		if child.name == node_name:
			return child
		var result = find_node_by_name(child, node_name)
		if result != null:
			return result
	return null

func build_astar_grid():
	cols = int(map_width / grid_size)
	rows = int(map_height / grid_size)
	var space_state = get_world_2d().direct_space_state
	
	var query = Physics2DShapeQueryParameters.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	query.set_shape(circle)
	query.collision_layer = 1 # Cùng layer với ObstaclePoly
	
	print("Bắt đầu quét bản đồ dò đường (AStar)...")
	
	# Vô hiệu hóa tạm thời va chạm của Player và NPCs để không cản AStar
	var characters = get_tree().get_nodes_in_group("npcs")
	var player = get_tree().root.get_node_or_null("World/YSort/Player")
	if player: characters.append(player)
	
	for c in characters:
		var shape = c.get_node_or_null("CollisionShape2D")
		if shape: shape.disabled = true
	
	# 1. Tạo các điểm (node)
	for y in range(rows):
		for x in range(cols):
			var pos = Vector2(x * grid_size + grid_size/2, y * grid_size + grid_size/2)
			query.transform = Transform2D(0, pos)
			var result = space_state.intersect_shape(query, 1)
			
			if result.empty():
				var id = y * cols + x
				astar.add_point(id, pos)
				
	# Bật lại va chạm
	for c in characters:
		var shape = c.get_node_or_null("CollisionShape2D")
		if shape: shape.disabled = false
	
	# 2. Nối các điểm với nhau
	for y in range(rows):
		for x in range(cols):
			var id = y * cols + x
			if not astar.has_point(id):
				continue
				
			var neighbors = [
				Vector2(x + 1, y),
				Vector2(x, y + 1),
				Vector2(x + 1, y + 1),
				Vector2(x - 1, y + 1)
			]
			
			for n in neighbors:
				if n.x >= 0 and n.x < cols and n.y >= 0 and n.y < rows:
					var n_id = n.y * cols + n.x
					if astar.has_point(n_id):
						astar.connect_points(id, n_id)
	
	print("Quét xong AStar với ", astar.get_point_count(), " điểm hợp lệ.")

func get_location_data(location_name: String):
	if town_locations.has(location_name):
		return town_locations[location_name]
	return null

func get_path_to_target(start_pos: Vector2, end_pos: Vector2) -> PoolVector2Array:
	# Nếu ở trong nhà, đi thẳng (vì trong nhà không có nhiều chướng ngại vật)
	if start_pos.x > 4900 or end_pos.x > 4900:
		return PoolVector2Array()
		
	if astar.get_point_count() == 0:
		return PoolVector2Array()
		
	var start_id = astar.get_closest_point(start_pos)
	var end_id = astar.get_closest_point(end_pos)
	
	if start_id == -1 or end_id == -1:
		return PoolVector2Array()
		
	return astar.get_point_path(start_id, end_id)
