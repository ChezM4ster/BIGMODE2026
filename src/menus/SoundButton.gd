extends Button
class_name SoundButton

@export var click_sound: AudioStream

var _audio_player: AudioStreamPlayer

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	
	add_child(_audio_player)
	_audio_player.stream = click_sound
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if _audio_player.stream:
		_audio_player.play()
