extends CharacterBody3D


var speed = 0.0
const RUN_SPEED = 5.0
const WALK_SPEED = 3.0
const JUMP_VELOCITY = 4.5
@onready var head: Node3D = $camera_mount
@onready var camera: Camera3D = $camera_mount/Camera3D
@export var sensitivity = 0.3

const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var bob_t = 0.0

const BASE_FOV = 45.0
const FOV_CHANGE = 7.5
var target_fov = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("run"):
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	
	bob_t += delta * velocity.length() * float(is_on_floor())
	head.transform.origin = bob(bob_t)
	
	var velocity_clamp = clamp(velocity.length(), 0.5, RUN_SPEED * 2.0)
	target_fov = BASE_FOV + FOV_CHANGE * velocity_clamp
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	move_and_slide()

func bob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
