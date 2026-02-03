extends Menu

signal GameStarted

@export var animation_path : AnimationPlayer
@export var player : PlayerCar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	Open()

func _on_start_game_pressed() -> void:
	$AnimationPlayer.play("slide")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	GameStarted.emit()
	Close()
	$right_panel.position.x = 993.0

func _on_speed_button_pressed() -> void:
	player.upgradesys.add("speed")

func _on_stearing_button_pressed() -> void:
	player.upgradesys.add("steering")

func _on_slickness_button_pressed() -> void:
	player.upgradesys.add("slickness")

func _on_power_button_pressed() -> void:
	player.upgradesys.add("power")
