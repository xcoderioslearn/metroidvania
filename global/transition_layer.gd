extends CanvasLayer

func _ready() -> void:
	$ColorRect.modulate.a = 0.0
	
func transition(target_level: Data.Level, current_level: Data.Level) :
	var tween = create_tween()
	tween.tween_property($ColorRect,"modulate:a",1.0, 0.8)
	tween.tween_interval(0.5)
	tween.tween_callback(_change_scene.bind(target_level,current_level))
	tween.tween_property($ColorRect,"modulate:a",0.0, 0.8)

func _change_scene(target_level: Data.Level, current_level: Data.Level):
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	var scene = load (Data.LEVEL_PATHS[target_level]).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	scene.position_player(current_level)
	Data.current_level = target_level
