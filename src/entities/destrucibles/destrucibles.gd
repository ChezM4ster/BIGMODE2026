extends StaticBody3D

@export var explosion_scene : PackedScene

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.get_parent() is PlayerCar:
		body.get_parent().camera_rig.camera_shake(0.07, 0.4)
		body.get_parent().camera_rig.freeze_frame(0.1, 0.07)
		var explosion : Node3D = explosion_scene.instantiate()
		add_child(explosion)
		$CollisionShape3D.queue_free()
		$Cylinder2.queue_free()
		explosion.global_position = self.global_position
		explosion.start_emitting()
		
