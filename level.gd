extends Node3D
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event):
	if event.is_action_pressed("lclick") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
