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
	"cafe_entrance": { "door_pos": Vector2(4518, 1947), "final_pos": Vector2(7319, 885) },
	"mayor_house":   { "door_pos": Vector2(1403, 1759), "final_pos": Vector2(5224, -218) },
	"clinic":        { "door_pos": Vector2(3999, 1118), "final_pos": Vector2(7504, 2469) },
	"workshop":      { "door_pos": Vector2(1071, 2393), "final_pos": Vector2(9218, 6136) },
	"town_hall":     { "door_pos": Vector2(2913, 1059),  "final_pos": Vector2(11133, 4245) },
	"library":       { "door_pos": Vector2(1845, 815),  "final_pos": Vector2(10997, 923) },
	"home_a":        { "door_pos": Vector2(1864, 2376),  "final_pos": Vector2(9189, 2498) },
	"home_b":        { "door_pos": Vector2(1999, 1773),  "final_pos": Vector2(9223, 4147) },
	"home_c":        { "door_pos": Vector2(1466, 2971),  "final_pos": Vector2(636, 4921) },
	"home_d":        { "door_pos": Vector2(1995, 3413),  "final_pos": Vector2(2213, 4921) },
	"home_e":        { "door_pos": Vector2(4149, 3207),  "final_pos": Vector2(3919, 4923) },
	"home_f":        { "door_pos": Vector2(5811, 2872),  "final_pos": Vector2(5642, 4914) },
	"market":        { "door_pos": Vector2(3827, 2058), "final_pos": Vector2(11036, 2583) },
	"dining_hall":   { "door_pos": Vector2(4002, 2630), "final_pos": Vector2(7422, 4131) },
	"dock":          { "door_pos": Vector2(2060, 2961), "final_pos": Vector2(9134, 876) }
}

func _ready():
	yield(get_tree(), "physics_frame")
	build_astar_grid()

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
