extends TileMap

# Từ giờ lưu thẳng tọa độ Pixel trên màn hình
var town_locations = {
	"spawn_player": Vector2(3000, 2000),
	"mayor_house": Vector2(2700, 2000),
	"park_center": Vector2(3000, 2300),    # Bãi đất trống giữa làng
	
	"cafe_entrance": {
		"door_pos": Vector2(3200, 2000), # Tọa độ cái cửa ngoài đường
		"final_pos": Vector2(10000, 10000) # Tọa độ bên trong
	}
}

func _ready():
	pass

# Hàm hỗ trợ NPC hoặc người chơi gọi để lấy tọa độ thế giới của 1 địa điểm
func get_location_data(location_name: String):
	if town_locations.has(location_name):
		return town_locations[location_name]
	return null
