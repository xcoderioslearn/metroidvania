extends CharacterBody2D


var direction: Vector2
var speed := 50
var player : CharacterBody2D
var health := 3 :
	set(value):
		health = value
		if health <= 0:
			explosion.emit(position)
			spawn_point.defeated = true
			queue_free()
var spawn_point : Marker2D
signal explosion(pos: Vector2)


func _on_player_detection_area_body_entered(body: Node2D) -> void:
	player = body

func _on_player_detection_area_body_exited(_body: Node2D) -> void:
	player = null


func _physics_process(_delta: float) -> void:
	if player:
		var dir = (player.position - position).normalized()
		velocity = dir * speed
		move_and_slide()

func hit():
	health -= 1
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D.material, 'shader_parameter/Progress', 1.0, 0.3)
	tween.tween_property($AnimatedSprite2D.material, 'shader_parameter/Progress', 0.0, 0.5)


func _on_collision_shape_2d_2_body_entered(_body: Node2D) -> void:
	explosion.emit(position)
	spawn_point.defeated = true
	queue_free()

func setup(new_spawn_point: Marker2D) :
	position = new_spawn_point.global_position
	spawn_point = new_spawn_point
