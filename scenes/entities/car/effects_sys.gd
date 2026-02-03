extends Node
class_name EfectSystem

class efect:
	static var ActiveEffects : Array[efect] = []
	
	var efect_time = 1
	var speed_mult := 1.0
	var steering_mult := 1.0
	var gravity_mult := 1.0
	var efect_timer: Timer = Timer.new()
	var root_node : Node
	
	signal efect_ended
	
	func _init(root_node_ : Node , stearing_mult_  = 1.0 , speed_mult_ = 1.0) -> void:
		root_node = root_node_
		steering_mult = stearing_mult_
		speed_mult = speed_mult_
		ActiveEffects.append(self)
		start_timer()
	
	func start_timer():
		root_node.add_child(efect_timer)
		efect_timer.start(efect_time)
		efect_timer.timeout.connect(end)
	
	func end():
		ActiveEffects.erase(self)
		efect_timer.queue_free()
		efect_ended.emit()

func add(efect_name : String):
	match efect_name:
		"oily":
			efect.new(self , 1.5 , 1.3)
		"boost":
			efect.new(self , 1 , 2)
		_:
			push_warning("unknown effect : " , efect_name )

func get_speed_mult():
	return efect.ActiveEffects.map(func(efec : efect): return efec.speed_mult - 1).reduce(func(accum, number): return accum + number, 0) + 1

func get_stearing_mult():
	return efect.ActiveEffects.map(func(efec : efect): return efec.steering_mult - 1).reduce(func(accum, number): return accum + number, 0) + 1
