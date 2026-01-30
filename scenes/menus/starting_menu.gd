extends Menu

signal GameStarted ### not used for now 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	Open()

func _on_start_game_pressed() -> void:
	Close()
	GameStarted.emit()
