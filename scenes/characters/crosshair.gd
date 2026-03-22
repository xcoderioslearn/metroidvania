extends Sprite2D

func update(direction: Vector2, distance: int, duck: bool):
	var offset_y  = 4 if duck else -6 
	position = direction * distance + Vector2(0,offset_y)
