extends Menu


func _ready() -> void:
	StopGame = false
	Open()


func _on_despawn_area_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
