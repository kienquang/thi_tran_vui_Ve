extends Node

func _ready():
	# Đã tạo phòng xong, không chạy lại nữa để tránh ghi đè đồ đạc bạn đã xếp!
	pass

func generate_rooms():
	print("Bắt đầu tạo các căn phòng từ assets...")
	var rooms_dir = "res://assets/rooms"
	var output_dir = "res://game/world/rooms"
	var rooms_added_count = 1
	
	var dir = Directory.new()
	if not dir.dir_exists(output_dir):
		dir.make_dir_recursive(output_dir)
		
	if dir.open(rooms_dir) == OK:
		dir.list_dir_begin()
		var room_name = dir.get_next()
		while room_name != "":
			if dir.current_is_dir() and not room_name.begins_with("."):
				var bg_path = rooms_dir + "/" + room_name + "/assets/background/room_shell.png"
				
				# Tạo Node gốc
				var root = Node2D.new()
				root.name = room_name.capitalize()
				
				# Tạo Background
				var bg_sprite = Sprite.new()
				bg_sprite.name = "Background"
				bg_sprite.texture = load(bg_path)
				bg_sprite.centered = false
				root.add_child(bg_sprite)
				bg_sprite.owner = root
				
				# Tạo YSort chứa đồ đạc
				var ysort = YSort.new()
				ysort.name = "YSort"
				root.add_child(ysort)
				ysort.owner = root
				
				# Quét thư mục furniture
				var furn_dir = rooms_dir + "/" + room_name + "/assets/furniture"
				var fdir = Directory.new()
				var offset_x = 100
				var offset_y = 100
				
				if fdir.open(furn_dir) == OK:
					fdir.list_dir_begin()
					var furn_name = fdir.get_next()
					while furn_name != "":
						if fdir.current_is_dir() and not furn_name.begins_with("."):
							var frames_dir = furn_dir + "/" + furn_name + "/frames"
							var frames_d = Directory.new()
							if frames_d.open(frames_dir) == OK:
								frames_d.list_dir_begin()
								var frame_file = frames_d.get_next()
								var picked_frame = ""
								while frame_file != "":
									if not frame_file.begins_with(".") and frame_file.ends_with(".png"):
										picked_frame = frames_dir + "/" + frame_file
										break
									frame_file = frames_d.get_next()
								
								if picked_frame != "":
									var f_sprite = Sprite.new()
									f_sprite.name = furn_name
									f_sprite.texture = load(picked_frame)
									f_sprite.position = Vector2(offset_x, offset_y)
									ysort.add_child(f_sprite)
									f_sprite.owner = root
									
									offset_x += 80
									if offset_x > 800:
										offset_x = 100
										offset_y += 80
						furn_name = fdir.get_next()
				
				# Lưu file Scene
				var packed = PackedScene.new()
				packed.pack(root)
				var room_path_str = output_dir + "/" + root.name + ".tscn"
				var err = ResourceSaver.save(room_path_str, packed)
				if err == OK:
					print("Đã tạo xong phòng: ", root.name)
				else:
					print("Lỗi khi lưu phòng: ", root.name)
					
			room_name = dir.get_next()
	print("Hoàn tất!")
