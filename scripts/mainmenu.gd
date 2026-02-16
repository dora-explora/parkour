extends PanelContainer

const TUTORIAL = preload("res://scenes/tutorial.tscn")
const LEVEL = preload("res://scenes/level1.tscn")

func _ready() -> void:
	$VBox/HBox/TutorialButton.pressed.connect(on_tutorial_pressed)
	$VBox/HBox/LevelButton.pressed.connect(on_level_pressed)
	$VBox/HBox/OptionsButton.pressed.connect(on_options_pressed)

func on_tutorial_pressed() -> void:
	get_tree().change_scene_to_packed(TUTORIAL)

func on_level_pressed() -> void:
	get_tree().change_scene_to_packed(LEVEL)

func on_options_pressed() -> void:
		pass
