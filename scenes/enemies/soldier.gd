extends CharacterBody2D

var direction : Vector2i = Vector2i.LEFT
var player : CharacterBody2D
var health := 2
var speed := 20
 
func move():
	velocity = direction * speed
	move_and_slide() 
	
func animation():
	$Sprite2D.flip_h = direction.x < 0
	if direction:
		$AnimationPlayer.current_animation = 'run'

func _physics_process(_delta: float) -> void:
	move()
	animation()


func _on_floor_left_area_body_exited(_body: Node2D) -> void:
	direction = Vector2i.RIGHT


func _on_floor_right_area_body_exited(_body: Node2D) -> void:
	direction = Vector2i.LEFT
	
