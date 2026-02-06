extends RayCast3D

@export var car : PlayerCar 

func _process(delta: float) -> void:
	if car.get_player_state() == car.AIR:
		global_rotation.x = 0
		global_rotation.z = 0
	else:
		rotation_degrees.x = 0 
		rotation_degrees.z = 0 
		
