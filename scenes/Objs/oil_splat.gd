extends Node3D
class_name OilSplat
signal end 
func start_emitting() -> void:
	$GPUParticles3D.emitting = true
	$GPUParticles3D2.emitting = true
	$GPUParticles3D3.emitting = true

func _on_gpu_particles_3d_3_finished() -> void:
	end_()

func end_():
	end.emit()
	queue_free()
