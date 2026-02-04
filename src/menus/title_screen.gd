class_name TitleScreen
extends Control

@export var mute_button: Button

func _on_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/levels/test_scene.tscn")

func _on_mute_button_pressed() -> void:
	SoundMenager.set_mute_main(!SoundMenager.master_sound_mute)
	if SoundMenager.master_sound_mute == true:
		mute_button.text = "unmute"
	else:
		mute_button.text = "mute"

func _on_settings_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/menus/MainMenu.tscn")
