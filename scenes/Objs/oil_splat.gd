extends Node3D


func start_emitting() -> void:
	$GPUParticles3D.emitting = true
	$GPUParticles3D2.emitting = true
	$GPUParticles3D3.emitting = true
	
	


func _on_gpu_particles_3d_3_finished() -> void:
	get_parent().queue_free()
