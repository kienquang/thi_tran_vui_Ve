extends TileMap

# Từ giờ lưu thẳng tọa độ Pixel trên màn hình (thay vì ô lưới cũ)
var town_locations = {
	"spawn_player": Vector2(3000, 2000),
	"cafe_entrance": Vector2(3200, 2000), # Gần chỗ cánh cửa Cafe
	"mayor_house": Vector2(2700, 2000),
	"park_center": Vector2(3000, 2300)    # Bãi đất trống giữa làng
}

func _ready():
	pass

# Hàm hỗ trợ NPC hoặc người chơi gọi để lấy tọa độ thế giới của 1 địa điểm
func get_location(location_name: String) -> Vector2:
	if town_locations.has(location_name):
		return town_locations[location_name]
	return Vector2.ZERO
