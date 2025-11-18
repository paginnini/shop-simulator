extends Camera3D

@export var move_speed: float = 10.0
@export var fast_speed: float = 15.0
@export var mouse_sensitivity: float = 0.15

var yaw: float = 0.0
var pitch: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -89, 89)
		rotation_degrees = Vector3(pitch, yaw, 0)

	# Escape releases mouse
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	var velocity = Vector3.ZERO

	# Build basis vectors from yaw only (ignore pitch for planar movement)
	var yaw_only_basis = Basis(Vector3.UP, deg_to_rad(yaw))
	var forward = -yaw_only_basis.z.normalized()
	var right = yaw_only_basis.x.normalized()

	# WASD movement (XZ plane)
	if Input.is_action_pressed("move_forward"):
		velocity += forward
	if Input.is_action_pressed("move_backward"):
		velocity -= forward
	if Input.is_action_pressed("move_left"):
		velocity -= right
	if Input.is_action_pressed("move_right"):
		velocity += right

	# Vertical movement
	if Input.is_action_pressed("move_up"):
		velocity.y += 1
	if Input.is_action_pressed("move_down"):
		velocity.y -= 1

	if velocity != Vector3.ZERO:
		velocity = velocity.normalized()

	var speed = move_speed

	global_position += velocity * speed * delta
