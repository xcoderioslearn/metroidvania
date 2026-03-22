extends Node2D

var bullet_scene = preload("res://scenes/bullets/bullet.tscn")
var explosion_scene = preload("res://scenes/bullets/explosion.tscn")
var enemy_scenes = {
	Data.Enemy.DRONE : preload("res://scenes/enemies/enemy_drone.tscn")
}
@onready var player = $Entities/Player

func _ready() -> void:
	
	for spawn_point : Marker2D in $EnemySpawns.get_children():
		if spawn_point.defeated == false:
			var enemy = enemy_scenes[spawn_point.type].instantiate()
			enemy.setup(spawn_point)
			$Entities.add_child(enemy)
	
	
	for enemy_drone in get_tree().get_nodes_in_group('Drones'):
		enemy_drone.connect('explosion', create_explosion)
		
func position_player(level: Data.Level):
	for gate in $Gates.get_children():
		if gate.target == level:
			player.position = gate.get_child(-1).global_position
			
func create_explosion(pos: Vector2):
	var explosion = explosion_scene.instantiate()
	explosion.setup(pos)
	call_deferred('_add_explosion', explosion)
func _add_explosion(explosion):
	$Bullets.add_child(explosion)

	
func _on_player_shoot(pos: Vector2, dir: Vector2, gun_type: Data.Gun) -> void:
	if gun_type != Data.Gun.SHOTGUN:
		var bullet = bullet_scene.instantiate()
		bullet.connect('explode' , create_explosion)
		$Bullets.add_child(bullet)
		bullet.setup(pos, dir, gun_type)
	else:
		for drone in get_tree().get_nodes_in_group('Drones'):
			var aim_angle = rad_to_deg(dir.angle())
			var enemy_angle = rad_to_deg((drone.position - pos).angle())
			if abs(aim_angle - enemy_angle) < 90 and pos.distance_to(drone.position) < 100:
				drone.hit()
				
				
			
			
