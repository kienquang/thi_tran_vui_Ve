extends SceneTree
func _init():
    var packed = load("res://game/world/World.tscn")
    var scene = packed.instance()
    var doors = []
    
    # Recursive function to find doors
    var stack = [scene]
    while stack.size() > 0:
        var node = stack.pop_back()
        if node.filename == "res://game/world/Door.tscn" or "Door" in node.name:
            if node.get("target_position") != null:
                doors.append({"name": node.name, "pos": var2str(node.position), "target_pos": var2str(node.target_position)})
        for i in range(node.get_child_count()):
            stack.append(node.get_child(i))
            
    var file = File.new()
    file.open("res://scratch_doors.json", File.WRITE)
    file.store_string(to_json(doors))
    file.close()
    quit()
