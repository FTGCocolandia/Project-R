extends Spatial

onready var ball = $Ball
onready var car_mesh = $CarMesh
onready var ground_ray = $CarMesh/RayCast

onready var body_mesh = $CarMesh/craft_speederA

export (bool) var show_debug = false
var sphere_offset = Vector3(0, 0.0, 0)
var acceleration = 50
var steering = 21
var turn_speed = 5
var turn_stop_limit = 0.75
var body_tilt = 35

var speed_input = 0
var rotate_input = 0

func _ready():
	ground_ray.add_exception(ball)
#	DebugOverlay.stats.add_property(ball, "linear_velocity", "length")
#	DebugOverlay.draw.add_vector(ball, "linear_velocity", 1, 4, Color(0, 1, 0, 0.5))
#	DebugOverlay.draw.add_vector(car_mesh, "transform:basis:z", -4, 4, Color(1, 0, 0, 0.5))

func _process(delta):
	# Can't steer/accelerate when in the air
	if not ground_ray.is_colliding():
		return
	# f/b input
	speed_input = 0
	speed_input += Input.get_action_strength("accelerate")
	speed_input -= Input.get_action_strength("brake") 
	speed_input *= acceleration
	# steer input
#	rotate_target = lerp(rotate_target, rotate_input, 5 * delta)
	rotate_input = 0
	rotate_input += Input.get_action_strength("steer_left")
	rotate_input -= Input.get_action_strength("steer_right")
	rotate_input *= deg2rad(steering)

	if Input.is_action_pressed("power2") and GameMaster.player_energy > 0:
		speed_input += 25
		GameMaster.player_energy -= 0.1

	if Input.is_action_just_released("power2"):
		speed_input = 0




	if Input.is_action_just_pressed("debugpower"):
		print("Energy: ", GameMaster.player_energy)
		print("Powers: ", GameMaster.player_powers)

	# rotate car mesh
	if ball.linear_velocity.length() > turn_stop_limit:
		var new_basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y, rotate_input)
		car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(new_basis, turn_speed * delta)
		car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
		
		# tilt body for effect
		var t = rotate_input * ball.linear_velocity.length() / body_tilt
		body_mesh.rotation.z = lerp(body_mesh.rotation.z, t, 10 * delta)

func _physics_process(delta):
#	car_mesh.transform.origin = ball.transform.origin + sphere_offset
	# just lerp the y due to trimesh bouncing
	car_mesh.transform.origin.x = ball.transform.origin.x + sphere_offset.x
	car_mesh.transform.origin.z = ball.transform.origin.z + sphere_offset.z
	car_mesh.transform.origin.y = lerp(car_mesh.transform.origin.y, ball.transform.origin.y + sphere_offset.y, 10 * delta)
#	car_mesh.transform.origin = lerp(car_mesh.transform.origin, ball.transform.origin + sphere_offset, 0.3)
	ball.add_central_force(-car_mesh.global_transform.basis.z * speed_input)
