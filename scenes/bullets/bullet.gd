extends Area2D

var direction: Vector2
var speed: int = 200
var type : Data.Gun
const OFFSET = 16
const TEXTURE = {
	Data.Gun.SINGLE: preload("res://graphics/fire/default.png"),
	Data.Gun.ROCKET: preload("res://graphics/fire/large.png"),	
}
signal explode(pos: Vector2,)

func _ready() -> void:
	$CollisionShape2D.disabled = true
	await get_tree().create_timer(0.2).timeout
	$CollisionShape2D.disabled = false

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func setup(pos: Vector2, dir: Vector2, gun_type: Data.Gun):
	position = pos + dir * OFFSET
	direction = dir
	type = gun_type
	$Sprite2D.texture = TEXTURE[gun_type]


func _on_body_entered(body: Node2D) -> void:
	if 'hit' in body:
		body.hit()
	if type == Data.Gun.ROCKET:
		explode.emit(position)
	queue_free()
	
