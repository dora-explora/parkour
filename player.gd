extends RigidBody3D

@export var speed = 6.
@export var acceleration = 3000.
@export var decceleration = 200.
@export var jump_impulse = 3
@export var jump_forward_impulse = 5
@export var h_sens = 0.15
@export var v_sens = 0.0015
@export var pushback = 10.

var _on_floor: bool = true

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if _on_floor && linear_velocity.length() < speed:
		apply_central_force(direction * acceleration * delta)
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") && _on_floor:
		apply_central_impulse(Vector3.UP * jump_impulse)
		apply_central_impulse(direction * jump_forward_impulse)
	
	arm_pushback($SpringArm3D)
	arm_pushback($SpringArm3D2)
	#$SpringArm3D.rotate_y((rotation.x - $SpringArm3D.rotation.y - 160))
	#$SpringArm3D2.rotate_y((rotation.x - $SpringArm3D2.rotation.y - 160))
	
func _input(event):
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_torque_impulse(Vector3(0, -event.relative.x * h_sens, 0))
		#$SpringArm3D.rotate_y(event.relative.x * h_sens / 50)
		#$SpringArm3D2.rotate_y(event.relative.x * h_sens / 50)
		$Camera.rotate_x(-event.relative.y * v_sens)
		$Camera.rotation.x = clampf($Camera.rotation.x, -deg_to_rad(60), deg_to_rad(70))

func _integrate_forces(state: PhysicsDirectBodyState3D):
	var on_floor: bool = false
	var i := 0
	while i < state.get_contact_count():
		var normal := state.get_contact_local_normal(i)
		on_floor = true if normal.dot(Vector3.UP) > 0.8 else false
		i += 1
	_on_floor = on_floor 
	
func arm_pushback(arm: SpringArm3D):
	var length = arm.get_length() - arm.get_hit_length()
	var pushbackstrength = pushback * length
	var pushbackdirection = arm.position - position
	apply_central_force(pushbackstrength * pushbackdirection)
	
