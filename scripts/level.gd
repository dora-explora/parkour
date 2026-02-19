extends Node3D

var _escaped = false;
var _stopwatch = 0.;

func _ready():
	$Player/Mesh.visible = false
	Input.use_accumulated_input = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for ledge in get_tree().get_nodes_in_group("ledge"):
		ledge.area_entered.connect($Player.on_ledge_entered.bind(ledge))
	$Lava/Area.area_entered.connect(on_lava)
	$DeathScreen/MarginContainer/VBoxContainer/HBoxContainer/Margin1/RetryButton.pressed.connect(on_retry_pressed)
	$DeathScreen/MarginContainer/VBoxContainer/HBoxContainer/Margin2/ExitButton.pressed.connect(on_exit_pressed)
	$Win/Area.area_entered.connect(on_win)
	$WinScreen/MarginContainer/VBoxContainer/HBoxContainer/Margin1/RetryButton.pressed.connect(on_retry_pressed)
	$WinScreen/MarginContainer/VBoxContainer/HBoxContainer/Margin2/ExitButton.pressed.connect(on_exit_pressed)
	$EscScreen/MarginContainer/VBoxContainer/HBoxContainer/Margin1/RetryButton.pressed.connect(on_retry_pressed)
	$EscScreen/MarginContainer/VBoxContainer/HBoxContainer/Margin2/ExitButton.pressed.connect(on_exit_pressed)
	$EscScreen/MarginContainer/VBoxContainer/HBoxContainer/Margin3/ReturnButton.pressed.connect(on_return_pressed)

func _input(event):
	if event.is_action_pressed("lclick") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE && !$Player._stopped:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("exit"):
		on_esc()

func _process(delta: float):
	if !$Player._stopped: _stopwatch += delta
	var ms = fmod(_stopwatch, 1) * 1000
	var s = fmod(_stopwatch, 60)
	var m = floor(_stopwatch / 60.)
	var string = "%02d : %02d : %02d"
	$TimeLabel.text = string % [m, s, ms]

func on_lava(area: Area3D):
	if area.name != "PlayerArea": return
	if $Player._stopped: return
	$Player._stopped = true
	Engine.time_scale = 0.
	$DeathScreen.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_win(area: Area3D):
	if area.name != "PlayerArea": return
	if $Player._stopped: return
	$Player._stopped = true
	Engine.time_scale = 0.2
	$WinScreen.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_esc():
	if $Player._stopped: return
	$Player._stopped = true
	Engine.time_scale = 0.
	_escaped = true
	$EscScreen.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_return_pressed():
	_escaped = false
	$EscScreen.visible = false
	$Player._stopped = false
	Engine.time_scale = 1.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return

func on_retry_pressed():
	$DeathScreen.visible = false
	$WinScreen.visible = false
	$EscScreen.visible = false
	_escaped = false
	_stopwatch = 0.
	Engine.time_scale = 1.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Player._moving = false
	$Player/ColliderL.disabled = false
	$Player/ColliderS.disabled = true
	$Player/Camera.rotation.x = 0.
	PhysicsServer3D.body_set_state($Player.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D.IDENTITY)
	PhysicsServer3D.body_set_state($Player.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	$Player._stopped = false

func on_exit_pressed():
	Engine.time_scale = 1.
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
