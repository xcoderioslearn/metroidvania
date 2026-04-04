extends CharacterBody2D

enum State { IDLE, RUN, DUCK, JUMP, FALL, DASH, FROZEN }

var state: State = State.IDLE
var direction_x: float
var controller_aim: bool
var target_dir: Vector2
var current_gun: Data.Gun
var on_floor: bool

var _wants_shoot: bool
var _wants_jump: bool
var _wants_dash: bool
var _wants_toggle: bool

@export_category('move')
@export var speed := 120
@export var acceleration: int = 600
@export var friction: int = 800
@export var dash_speed: int = 600
@export var duck_speed_multiplier: float = 0.4
@export_category('jump')
@export var jump_height: float = 100
@export var jump_time_to_peak: float = 0.5
@export var jump_time_to_descent: float = 0.4
@export_category('shooting')
@export var crosshair_distance: int = 50
@export var shotgun_distance: int = 30

@onready var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_descent)) * -1.0

signal shoot(pos: Vector2, dir: Vector2, gun_type: Data.Gun)

const GUN_DIRECTIONS = {
	Vector2i(0,0):   0, Vector2i(1,0):   0, Vector2i(1,1):   1,
	Vector2i(0,1):   2, Vector2i(-1,1):  3, Vector2i(-1,0):  4,
	Vector2i(-1,-1): 5, Vector2i(0,-1):  6, Vector2i(1,-1):  7,
}


func _ready() -> void:
	$UI.set_health(Data.player_health)

func _input(event: InputEvent) -> void:
	print(event)
	if Input.get_vector("aim_left","aim_right","aim_up","aim_down"):
		controller_aim = true
	if event is InputEventMouseMotion:
		controller_aim = false
	if event is InputEventMouseButton or event is InputEventKey:
		event = event.duplicate()
		if event is InputEventMouseButton:
			event.ctrl_pressed = false
			event.shift_pressed = false
			event.alt_pressed = false
		elif event is InputEventKey:
			event.ctrl_pressed = false
			event.shift_pressed = false
			event.alt_pressed = false
	if event.is_action_pressed("shoot"):  _wants_shoot  = true 
	if event.is_action_pressed("jump"):   _wants_jump   = true
	if event.is_action_pressed("dash"):   _wants_dash   = true
	if event.is_action_pressed("toggle"): _wants_toggle = true

func _physics_process(delta: float) -> void:
	if state == State.FROZEN:
		return
	direction_x = Input.get_axis("left", "right")
	_transition(delta)
	_process_state(delta)
	_handle_shoot()
	_handle_gun_toggle()
	_animate()
	on_floor = is_on_floor()
	move_and_slide()
	_wants_shoot  = false
	_wants_jump   = false
	_wants_dash   = false
	_wants_toggle = false

func _process(_delta: float) -> void:
	$Sprites/Crosshair.update(get_aim_dir(), crosshair_distance, state == State.DUCK)
	if on_floor and not is_on_floor() and velocity.y >= 0:
		$Timer/CoyoteTimer.start()

# ─── state transitions ────────────────────────────────────────────────────────

func _transition(_delta: float) -> void:
	match state:
		State.IDLE, State.RUN:
			if _wants_dash and not $Timer/DashTimer.time_left:
				_enter_state(State.DASH)
				return
			if _wants_jump and (is_on_floor() or $Timer/CoyoteTimer.time_left):
				_enter_state(State.JUMP)
				return
			if Input.is_action_pressed("duck") and is_on_floor():
				_enter_state(State.DUCK)
				return
			if not is_on_floor():
				_enter_state(State.FALL)
				return
			if direction_x != 0:
				_enter_state(State.RUN)
			else:
				_enter_state(State.IDLE)

		State.DUCK:
			if _wants_jump and (is_on_floor() or $Timer/CoyoteTimer.time_left):
				_enter_state(State.JUMP)
				return
			if not Input.is_action_pressed("duck") or not is_on_floor():
				_enter_state(State.IDLE)

		State.JUMP:
			if _wants_dash and not $Timer/DashTimer.time_left:
				_enter_state(State.DASH)
				return
			if velocity.y >= 0:
				_enter_state(State.FALL)

		State.FALL:
			if _wants_dash and not $Timer/DashTimer.time_left:
				_enter_state(State.DASH)
				return
			if is_on_floor():
				_enter_state(State.IDLE)

		State.DASH:
			pass

func _enter_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	match state:
		State.JUMP:
			velocity.y = jump_velocity
		State.DASH:
			$Timer/DashTimer.start()
			var tween = create_tween()
			tween.tween_property(self, 'velocity:x', velocity.x + direction_x * dash_speed, 0.3)
			tween.tween_callback(_dash_finish)

# ─── per-state physics ────────────────────────────────────────────────────────

func _process_state(delta: float) -> void:
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

		State.RUN:
			velocity.x = move_toward(velocity.x, direction_x * speed, acceleration * delta)

		State.DUCK:
			if direction_x:
				velocity.x = move_toward(velocity.x, direction_x * (speed * duck_speed_multiplier), acceleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, friction * delta * 2)

		State.JUMP, State.FALL:
			if direction_x:
				velocity.x = move_toward(velocity.x, direction_x * speed, acceleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.y += _get_gravity() * delta

		State.DASH:
			velocity.y += _get_gravity() * delta

func _get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func _dash_finish() -> void:
	velocity.x = move_toward(velocity.x, 0, 500)
	_enter_state(State.FALL if not is_on_floor() else State.IDLE)

# ─── animation ────────────────────────────────────────────────────────────────

func _animate() -> void:
	if direction_x != 0:
		$Sprites/LegSprite.flip_h = direction_x < 0

	var anim := _match_anim()
	if $AnimationPlayer.current_animation != anim:
		$AnimationPlayer.play(anim)

	var raw_dir := get_aim_dir()
	var adjusted_dir := Vector2i(round(raw_dir.x), round(raw_dir.y))
	$Sprites/TorsoSprite.frame = GUN_DIRECTIONS[adjusted_dir] + int(current_gun) * $Sprites/TorsoSprite.hframes
	$Sprites/TorsoSprite.position.y = 0 if state == State.DUCK else -8

func _match_anim() -> String:
	match state:
		State.IDLE:  return "idle"
		State.RUN:   return "run"
		State.DUCK:  return "duck"
		State.DASH:  return "run"
		_:           return "jump"


func _handle_shoot() -> void:
	if _wants_shoot and not $Timer/ReloadTimer.time_left:
		shoot.emit(position, get_aim_dir(), current_gun)
		$Timer/ReloadTimer.start()
		if current_gun == Data.Gun.SHOTGUN:
			$ShotgunParticles.position = get_aim_dir() * shotgun_distance
			$ShotgunParticles.process_material.set('direction', get_aim_dir())
			$ShotgunParticles.emitting = true

func _handle_gun_toggle() -> void:
	if _wants_toggle:
		current_gun = posmod(current_gun + 1, Data.Gun.size()) as Data.Gun

# ─── public api ───────────────────────────────────────────────────────────────

func hit() -> void:
	Data.player_health -= 1
	$UI.set_health(Data.player_health)

func freeze() -> void:
	state = State.FROZEN
	$AnimationPlayer.pause()

func get_aim_dir() -> Vector2:
	if controller_aim:
		var dir := Input.get_vector("aim_left","aim_right","aim_up","aim_down")
		if dir.length():
			target_dir = dir.normalized()
	else:
		target_dir = get_local_mouse_position().normalized()
	return target_dir
