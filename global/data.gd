extends Node

enum Gun {SINGLE, SHOTGUN, ROCKET}
enum Level {SUBWAY, SKY, SUBWAY_2}
enum Enemy {DRONE,SOLDIER}
const LEVEL_PATHS = {
	Level.SUBWAY : "res://scenes/levels/subway.tscn",
	Level.SKY : "res://scenes/levels/sky.tscn",
	Level.SUBWAY_2 : "res://scenes/levels/subway_2.tscn",
}
var current_level : Level = Level.SUBWAY

var player_health : int = 5
var enemy_data : Dictionary
