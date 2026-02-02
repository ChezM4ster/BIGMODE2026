extends Node
class_name EfectSystem

class efect:
	var efect_time = 1
	var speed_mult := 1.0
	var steering_mult := 1.0
	var gravity_mult := 1.0
	var efect_timer: Timer = Timer.new()
	signal efect_ended
	
	func start_timer(root_node : Node):
		root_node.add_child(efect_timer)
		efect_timer.start(efect_time)
		efect_timer.timeout.connect(end.bind(efect_timer))
		
	func end(timer : Timer):
		timer.queue_free()
		efect_ended.emit()
 
var ActiveEffects : Array[efect] = []

func add_effect(efect_name : String):
	var new_efect = efect.new()
	match efect_name:
		"oily":
			new_efect.steering_mult = 2
			new_efect.speed_mult = 1.3
		"boost":
			new_efect.speed_mult = 2
			
	new_efect.start_timer(self)
	new_efect.efect_ended.connect(end_efect.bind(new_efect) )
	ActiveEffects.append(new_efect)

func end_efect(efect_ :efect):
	ActiveEffects.erase(efect_)

func get_speed_mult():
	return  ActiveEffects.map(func(efec : efect): return efec.speed_mult - 1).reduce(func(accum, number): return accum + number, 0) + 1

func get_stearing_mult():
	return  ActiveEffects.map(func(efec : efect): return efec.steering_mult - 1).reduce(func(accum, number): return accum + number, 0) + 1
