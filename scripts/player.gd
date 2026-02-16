extends RigidBody3D

var speed = 6.
var acceleration = 10000.
var aircceleration = 1000.
var jump_impulse = 5.
var jump_forward_impulse = 5.
var h_sens = 0.15
var v_sens = 0.0025
var hand_length = 2.
#var pushback = 5000.
var pushback = 0.
#var v_pushback = 0.2
var v_pushback = 0.
var foot_pushback = 1000.
var arm_min = 30.
var getup_impulse = 7.
var ledge_pullstrength = 1000.
var ledge_movestrength = 800.

var _on_floor: bool = true
var _moving: bool = false
var _handsav := [Vector2.ZERO, Vector2.ZERO]
var _feetav := [Vector2.ZERO, Vector2.ZERO]
var _grabbings: Array[Area3D] = [null, null]

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if _on_floor && linear_velocity.length() < speed:
		apply_central_force(direction * acceleration * delta)

	if !_on_floor && direction:
		var horizontal_velocity = Vector3(linear_velocity.x, 0, linear_velocity.z)
		if horizontal_velocity.length() >= speed:
			apply_central_force(-horizontal_velocity.normalized() * aircceleration * delta)
		apply_central_force(direction * aircceleration * delta)

	if _on_floor: physics_material_override.friction = 3.
	else: physics_material_override.friction = 0.

	if Input.is_action_just_pressed("jump") && _on_floor && !_moving:
		apply_central_impulse(Vector3.UP * jump_impulse)
		apply_central_impulse(direction * jump_forward_impulse)
		_moving = true
		$ColliderL.disabled = true
		$ColliderS.disabled = false

	var shift = Input.is_action_pressed("shift")
	var lclick = Input.is_action_pressed("lclick")
	var rclick = Input.is_action_pressed("rclick")

	process_arm(shift && lclick, $LHand, $Camera/FakeLHand, $LedgeLHand, 0, delta)
	process_arm(shift && rclick, $RHand, $Camera/FakeRHand, $LedgeRHand, 1, delta)

	process_leg(not shift && lclick, input_dir.y, $LFoot, $FakeLFoot, 0, delta)
	process_leg(not shift && rclick, input_dir.y, $RFoot, $FakeRFoot, 1, delta)

func process_arm(held: bool, hand: Node3D, fake: Node3D, ledgehand: Node3D, index: int, delta: float):
	if _grabbings[index]:
		if !held:
			ledgehand.visible = false
			_grabbings[index] = null
			hand.position = Vector3.ZERO
			fake.visible = true
			return
		_handsav[index] = Vector2.ZERO
		hand.visible = false
		fake.visible = false
		during_ledge(_grabbings[index], delta)

	elif held:
		arm_posrot(hand, index, delta)
		arm_pushback(hand.get_node("Arm"), index, delta)
		hand.visible = true
		fake.visible = false
	else:
		_handsav[index] = Vector2.ZERO
		hand.position = Vector3.ZERO
		hand.visible = false
		fake.visible = true

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

func arm_pushback(arm: SpringArm3D, index: int, delta: float):
	var length = arm.get_length() - arm.get_hit_length()
	var pbstrength = pushback * length
	if _grabbings[(index + 1) % 2]: pbstrength /= 5.
	var rawpbdir = arm.global_position - position
	var pbdir = Vector3(-rawpbdir.x, v_pushback * (arm.rotation.x), -rawpbdir.z)
	apply_central_force(pbstrength * pbdir * delta)

func on_ledge_entered(area: Area3D, ledge: Area3D):
	if area.name == "LHandArea":
		if _grabbings[1] == ledge: return
		_grabbings[0] = ledge
		$LHand.visible = false
		$LedgeLHand.visible = true
		$LedgeLHand.global_position = ledge.global_position
		$LedgeLHand.global_rotation = ledge.global_rotation
	else:
		if _grabbings[0] == ledge: return
		_grabbings[1] = ledge;
		$RHand.visible = true
		$LedgeRHand.visible = true
		$LedgeRHand.global_position = ledge.global_position
		$LedgeRHand.global_rotation = ledge.global_rotation

func during_ledge(ledge: Area3D, delta: float):
	var diff = ledge.global_position - $Camera.global_position
	var pdir = diff.normalized()
	var pstrength = ledge_pullstrength
	var dist = diff.length()
	if dist < 1.:
		pstrength *= (2. - 2. / dist)
	else:
		pstrength *= pow(dist - 1., 2.)
	apply_central_force(pdir * delta * pstrength)
	var cdir = $Camera.global_basis * Vector3.FORWARD
	var ddir = pdir - cdir
	var mdir = Vector3(ddir.x, ddir.y * 1.5, ddir.z)
	var mstrength = ledge_movestrength
	apply_central_force(mdir * mstrength * delta)

func process_leg(held: bool, forward: float, foot: Node3D, fake: Node3D, index: int, delta: float):
	if held && _moving:
		leg_posrot(foot, index, delta)
		var lookingatwall = false
		if $Camera/RayCast3D.is_colliding():
			if $Camera/RayCast3D.get_collision_normal().y < 0.5:
				lookingatwall = true
		leg_pushback(foot, forward != 1. && lookingatwall, index, delta)
		foot.visible = true
		fake.visible = false
	else:
		foot.visible = false
		fake.visible = true

func leg_posrot(foot: Node3D, index: int, delta: float):
	foot.global_position = position + Vector3(0., 1.4, 0.) * basis
	var foot_error = rotation.y - foot.rotation.y
	if foot_error < -PI: foot_error += TAU
	if foot_error > PI: foot_error -= TAU
	_feetav[index].y += foot_error * 4
	_feetav[index].y /= 1.4
	foot.rotate_y(_feetav[index].y * delta)
	var leg = foot.get_node("Leg")
	#var error = ($Camera.rotation.x * 1.3) - leg.rotation.x + PI - PI/8
	var error = $Camera.rotation.x - leg.rotation.x + 3*PI/4
	if error > PI: error -= TAU
	_feetav[index].x += error * 4
	_feetav[index].x /= 1.3
	leg.rotate_x(_feetav[index].x * delta)

func leg_posrot_snap(foot: Node3D):
	foot.global_position = position + Vector3(0., 1.4, 0.) * basis
	var foot_error = rotation.y - foot.rotation.y
	foot.rotate_y(foot_error)
	var leg = foot.get_node("Leg")
	var error = $Camera.rotation.x - leg.rotation.x + 3*PI/4
	leg.rotate_x(error)

func leg_pushback(foot: Node, gp: bool, index: int, delta: float):
	var leg = foot.get_node("Leg")
	var length = (leg.get_length() - leg.get_hit_length()) / leg.get_length()
	var pbstrength = 1000. * pow(length, 0.3)
	var xkick = .5 - _feetav[index].x
	var xdir = sin(leg.rotation.x - PI/2) * sin(rotation.y) * xkick
	var ydir = cos(leg.rotation.x - PI/2) * 2.
	var zdir = sin(leg.rotation.x - PI/2) * cos(rotation.y) * xkick
	if gp: ydir /= 5.	# stands for glitch protection btw
	var pbdir = Vector3(xdir, ydir, zdir)
	apply_central_force(pbstrength * pbdir * delta)

func _on_timer_timeout():
	if _moving && _on_floor:
		apply_central_impulse(Vector3.UP * getup_impulse)
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
