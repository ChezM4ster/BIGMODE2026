extends Node3D

@onready var explosion_preload = preload("res://assets/models/svx/explosion.tscn")

func _on_car_controller_explode() -> void:
	var explosion : GPUParticles3D = explosion_preload.instantiate()
	explosion.emitting = true
	explosion.one_shot = true
	add_child(explosion)
	explosion.global_position = $CarController.ball.global_position
	$CarController.kill_player()
	var timer = Timer.new()
	add_child(timer)
	timer.start(explosion.lifetime)
	await timer.timeout
	$UI/StartingMenu.Open()

func _on_starting_menu_game_started() -> void:
	$CarController.revive_player()
