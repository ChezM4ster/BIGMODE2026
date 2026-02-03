extends Menu

signal GameStarted ### not used for now 

@export var animation_path : PathFollow2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	Open()

func _on_start_game_pressed() -> void:
	$AnimationPlayer.play("slide")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	GameStarted.emit()
	Close()
	$right_panel.position.x = 993.0
