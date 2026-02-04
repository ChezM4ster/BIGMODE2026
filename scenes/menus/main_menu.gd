extends Control

@export var MusicSlider: HSlider
@export var SFXSlider: HSlider

func _on_exit_pressed() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/menus/title_screen.tscn")

func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	SoundMenager.set_volume_sfx(MusicSlider.value) ## # put some function here so the value fits

func _on_music_slider_drag_ended(_value_changed: bool) -> void:
	SoundMenager.set_volume_music(MusicSlider.value)
