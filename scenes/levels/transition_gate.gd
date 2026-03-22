extends Area2D

@export var target: Data.Level

func _on_body_entered(player: CharacterBody2D) -> void:
	player.freeze()
	TransitionLayer.transition(target, Data.current_level)
