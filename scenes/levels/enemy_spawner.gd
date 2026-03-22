extends Marker2D

@export var type : Data.Enemy
var unique_id : String 
var defeated: bool :
	set(value):
		defeated = value
		Data.enemy_data[unique_id]['defeated'] = value

func _enter_tree() -> void:
	unique_id = get_unique_id()
	if unique_id not in  Data.enemy_data:
		Data.enemy_data[unique_id] = {'defeated': defeated}
	else:
		defeated = Data.enemy_data[unique_id]['defeated']
	

func get_unique_id() -> String:
	var scene_name = get_owner().scene_file_path.get_file().get_basename()
	return str(scene_name) + "_" + str(name)
