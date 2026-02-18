extends PanelContainer

const TUTORIAL = preload("res://scenes/tutorial.tscn")
const LEVEL = preload("res://scenes/level1.tscn")

func _ready() -> void:
	$VBox/HBox/TutorialButton.pressed.connect(on_tutorial_pressed)
	$VBox/HBox/LevelButton.pressed.connect(on_level_pressed)
	$VBox/HBox/QuitButton.pressed.connect(on_quit_pressed)
	
func _input(event: InputEvent):
	if event.is_action_pressed("exit"): get_tree().quit()

func on_tutorial_pressed() -> void:
	get_tree().change_scene_to_packed(TUTORIAL)

func on_level_pressed() -> void:
	get_tree().change_scene_to_packed(LEVEL)

func on_quit_pressed() -> void:
		get_tree().quit()
