extends Node3D

func _ready():
	$Player/Mesh.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for ledge in get_tree().get_nodes_in_group("ledge"):
		# print("connecting ", ledge.name)
		ledge.area_entered.connect($Player.on_ledge_entered.bind(ledge))
	$Lava/Area.area_entered.connect(on_lava)

func _input(event):
	if event.is_action_pressed("lclick") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_lava(area: Area3D):
	print(area.name, " has touched the floor")
	if area.name == "PlayerArea": # kill the playerf
		$Player.position = Vector3.ZERO
