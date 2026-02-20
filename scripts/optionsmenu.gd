extends PanelContainer

func _ready():
	var fov_string = "FOV: %d°"
	$VBox/Margin1/FOVLabel.text = fov_string % globals.fov
	var sens_string = "Sensitivity: %d%%"
	$VBox/Margin2/SensLabel.text = sens_string % (globals.sens * 100)
	$VBox/Margin1/FOVSlider.value = globals.fov
	$VBox/Margin2/SensitivitySlider.value = globals.sens
	$VBox/Margin1/FOVSlider.value_changed.connect(on_fov_value_changed)
	$VBox/Margin2/SensitivitySlider.value_changed.connect(on_sens_value_changed)
	$VBox/Margin3/BackButton.pressed.connect(on_back_pressed)

func on_fov_value_changed(value: float) -> void:
	var fov_string = "FOV: %d°"
	$VBox/Margin1/FOVLabel.text = fov_string % value
	globals.fov = value

func on_sens_value_changed(value: float) -> void:
	var sens_string = "Sensitivity: %d%%"
	$VBox/Margin2/SensLabel.text = sens_string % (value * 100)
	globals.sens = value

func on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
