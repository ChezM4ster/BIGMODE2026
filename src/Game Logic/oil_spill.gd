class_name OilSpill
extends Node3D

func _on_player_detector_body_entered(body) -> void:
	if body.get_parent() is PlayerCar:
		print("Player on oil")
		body.get_parent().enter_oil()

func _on_player_detector_body_exited(body) -> void:
	if body.get_parent() is PlayerCar:
		print("Player on oil")
		body.get_parent().exit_oil()
