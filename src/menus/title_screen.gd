class_name TitleScreen

extends Control



func _on_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/levels/test_scene.tscn")
