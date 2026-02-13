extends RigidBody3D

var speed = 6.
var acceleration = 10000.
var decceleration = 0.
var jump_impulse = 3
var jump_forward_impulse = 5
var h_sens = 0.15
var v_sens = 0.0025
var hand_length = 2.
var pushback = 5000.
var v_pushback = 0.2
@export var foot_pushback = 200.
var arm_min = 30.
var getup_impulse = 3.

var _on_floor: bool = true
var _moving: bool = false
var _handsav := [Vector2.ZERO, Vector2.ZERO]
var _feetav := [Vector2.ZERO, Vector2.ZERO]

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if _on_floor && linear_velocity.length() < speed:
		apply_central_force(direction * acceleration * delta)

	if Input.is_action_just_pressed("jump") && _on_floor && !_moving:
		apply_central_impulse(Vector3.UP * jump_impulse)
		apply_central_impulse(direction * jump_forward_impulse)
		_moving = true
		$ColliderL.disabled = true
		$ColliderS.disabled = false

	if Input.is_action_pressed("shift") && Input.is_action_pressed("lclick"):
		arm_posrot($LHand, 0, delta)
		arm_pushback($LHand/Arm, delta)
		$LHand.visible = true
		$Camera/FakeLHand.visible = false
	else:
		$LHand.visible = false
		$Camera/FakeLHand.visible = true
	if Input.is_action_pressed("shift") && Input.is_action_pressed("rclick"):
		arm_posrot($RHand, 0, delta)
		arm_pushback($RHand/Arm, delta)
		$RHand.visible = true
		$Camera/FakeRHand.visible = false
	else:
		$RHand.visible = false
		$Camera/FakeRHand.visible = true
		
	if !Input.is_action_pressed("shift") && Input.is_action_pressed("lclick") && _moving:
		leg_posrot($LFoot, 0, delta)
		leg_pushback($LFoot, 0, delta)
		$LFoot.visible = true
		$FakeLFoot.visible = false
	else:
		$LFoot.visible = false
		$FakeLFoot.visible = true
	if !Input.is_action_pressed("shift") && Input.is_action_pressed("rclick") && _moving:
		leg_posrot($RFoot, 0, delta)
		leg_pushback($RFoot, 1, delta)
		$RFoot.visible = true
		$FakeRFoot.visible = false
	else:
		$RFoot.visible = false
		$FakeRFoot.visible = true
		
func arm_posrot(hand: Node3D, index: int, delta: float):
	hand.global_position = position + Vector3(0., 1.4, 0.) * basis
	var hand_error = rotation.y + PI - hand.rotation.y
	if hand_error > PI: hand_error -= TAU
	_handsav[index].y += hand_error * 5
	_handsav[index].y /= 1.4
	hand.rotate_y(_handsav[index].y * delta)
	var arm = hand.get_node("Arm")
	var target = max($Camera.rotation.x, deg_to_rad(-arm_min if !_moving else 0.))
	var error = -target - arm.rotation.x
	_handsav[index].x += error * 4
	_handsav[index].x /= 1.3
	arm.rotate_x(_handsav[index].x * delta)

func arm_posrot_snap(hand: Node3D):
	hand.global_position = position + Vector3(0., 1.4, 0.) * basis
	var hands_error = rotation.y + PI - hand.rotation.y
	hand.rotate_y(hands_error)
	var arm = hand.get_node("Arm")
	var target = max($Camera.rotation.x, deg_to_rad(-arm_min if !_moving else 0.))
	var error = -target - arm.rotation.x
	arm.rotate_x(error)
	
func arm_pushback(hand: SpringArm3D, delta: float):
	var length = hand.get_length() - hand.get_hit_length()
	var pbstrength = pushback * length
	var rawpbdir = hand.global_position - position
	var pbdir = Vector3(-rawpbdir.x, v_pushback * (hand.rotation.x), -rawpbdir.z)
	apply_central_force(pbstrength * pbdir * delta)

func leg_posrot(foot: Node3D, index: int, delta: float):
	foot.global_position = position + Vector3(0., 1.4, 0.) * basis
	var foot_error = rotation.y - foot.rotation.y
	if foot_error < -PI: foot_error += TAU
	if foot_error > PI: foot_error -= TAU
	_feetav[index].y += foot_error * 4
	_feetav[index].y /= 1.4
	foot.rotate_y(_feetav[index].y * delta)
	var leg = foot.get_node("Leg")
	var error = ($Camera.rotation.x * 1.3) - leg.rotation.x + PI - PI/8
	if error > PI: error -= TAU
	_feetav[index].x += error * 4
	_feetav[index].x /= 1.3
	leg.rotate_x(_feetav[index].x * delta)

func leg_posrot_snap(foot: Node3D):
	foot.global_position = position + Vector3(0., 1.4, 0.) * basis
	var foot_error = rotation.y - foot.rotation.y
	foot.rotate_y(foot_error)
	var leg = foot.get_node("Leg")
	var error = ($Camera.rotation.x * 1.3) - leg.rotation.x + PI - PI/8
	leg.rotate_x(error)
	
func leg_pushback(foot: Node, index: int, delta: float):
	var leg = foot.get_node("Leg")
	var length = leg.get_length() - leg.get_hit_length()
	var pbstrength = foot_pushback * length
	var xkick = (1 - _feetav[index].x * 10.)
	var xdir = sin(leg.rotation.x - PI/2) * sin(rotation.y) * xkick
	var ydir = cos(leg.rotation.x - PI/2) * 2.
	var zdir = sin(leg.rotation.x - PI/2) * cos(rotation.y) * xkick
	var pbdir = Vector3(xdir, ydir, zdir)
	apply_central_force(pbstrength * pbdir * delta)
	
func _on_timer_timeout():
	if _moving && _on_floor:
		apply_central_impulse(Vector3.UP * getup_impulse)
		_on_floor = false
		_moving = false
		$ColliderL.disabled = false
		$ColliderS.disabled = true

func _input(event):
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_torque_impulse(Vector3(0, -event.relative.x * h_sens, 0))
		$Camera.rotate_x(-event.relative.y * v_sens)
		$Camera.rotation.x = clampf($Camera.rotation.x, -deg_to_rad(80), deg_to_rad(70))
	if event.is_action("lclick") && Input.is_action_pressed("shift"):
		arm_posrot_snap($LHand)
	if event.is_action("rclick") && Input.is_action_pressed("shift"):
		arm_posrot_snap($RHand)
	if event.is_action("lclick") && !Input.is_action_pressed("shift"):
		leg_posrot_snap($LFoot)
	if event.is_action("rclick") && !Input.is_action_pressed("shift"):
		leg_posrot_snap($RFoot)

func _integrate_forces(state: PhysicsDirectBodyState3D):
	var on_floor: bool = false
	var i := 0
	while i < state.get_contact_count():
		var normal := state.get_contact_local_normal(i)
		if normal.dot(Vector3.UP) > 0.99: on_floor = true
		i += 1
	_on_floor = on_floor 
	if _moving && on_floor && $Timer.is_stopped():
		$Timer.start()
	
