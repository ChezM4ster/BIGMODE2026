extends CanvasLayer


func change_scene(scene_path : String):
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	
	ResourceLoader.load_threaded_request(scene_path)
	
	## Loading system with inspiration taken from Miziziziz
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path)
		print("Loading status: ", status)
	
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("Failed to load scene: " + scene_path)
		return
	else:
		var packed_scene := ResourceLoader.load_threaded_get(scene_path)
		get_tree().change_scene_to_packed(packed_scene)
	
	$AnimationPlayer.play_backwards("fade_in")
