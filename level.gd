extends Node3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for ledge in get_tree().get_nodes_in_group("ledge"):
		print("connecting ", ledge.name)
		ledge.area_entered.connect($Player.on_ledge_entered.bind(ledge))
		ledge.area_exited.connect($Player.on_ledge_exited.bind(ledge))
	
func _input(event):
	if event.is_action_pressed("lclick") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
