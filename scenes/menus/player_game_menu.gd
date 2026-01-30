extends Menu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
 
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if Opened:
		Close()
	else:
		Open()
