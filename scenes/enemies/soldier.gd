extends CharacterBody2D

var direction : Vector2 = Vector2.LEFT
var player : CharacterBody2D
var health := 2
var speed := 20
var spawn_point : Marker2D
signal shoot(pos: Vector2,dir: Vector2,gun_type: Data.Gun)
 
func move():
	velocity = direction * speed *int(player is not CharacterBody2D)
	velocity.y = get_gravity().y
	move_and_slide() 
	
func animation():
	if health > 0:
		$Sprite2D.flip_h = direction.x < 0
		if direction:
			$AnimationPlayer.current_animation = 'run'
			
		if player:
			var pos_difference =  player.position - position
			$Sprite2D.flip_h = pos_difference.x < 0
			$AnimationPlayer.current_animation = 'shoot_h' if pos_difference.y > -60 else 'shoot_v'
	else:
		$AnimationPlayer.current_animation = 'death'
func stay_dead():
	$AnimationPlayer.active = false
	$Sprite2D.frame = 22
	direction = Vector2i.ZERO
	$CollisionShape2D.disabled = true

func _physics_process(_delta: float) -> void:
	move()
	animation()


func hit():
	health -= 1
	if health <= 0:
		player = null
	var tween = create_tween()
	tween.tween_property($Sprite2D.material, 'shader_parameter/Progress', 1.0, 0.3)
	tween.tween_property($Sprite2D.material, 'shader_parameter/Progress', 0.0, 0.5)
	

func _on_floor_left_area_body_exited(_body: Node2D) -> void:
	direction = Vector2i.RIGHT


func _on_floor_right_area_body_exited(_body: Node2D) -> void:
	direction = Vector2i.LEFT
	


func _on_player_area_body_entered(body: Node2D) -> void:
	player = body
	$ShootTimer.start()

func _on_player_area_body_exited(body: Node2D) -> void:
	player = null


func _on_shoot_timer_timeout() -> void:
	if player :
		var dir = (player.position - position).normalized()
		shoot.emit(position + dir * 10,dir,Data.Gun.SINGLE)
		
func setup(new_spawn_point: Marker2D) :
	position = new_spawn_point.global_position
	spawn_point = new_spawn_point
