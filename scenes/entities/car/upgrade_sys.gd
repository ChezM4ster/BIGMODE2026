extends Node
class_name UpgradeSys

class upgrade:
	static var AllUpgrades: Array[upgrade] = []
	
	var efect_time = 1
	var speed_mult := 1.0
	var steering_mult := 1.0
	var gravity_mult := 1.0
	var root_node: Node

	func _init(root_node_: Node, stearing_mult_ = 1.0, speed_mult_ = 1.0) -> void:
		root_node = root_node_
		steering_mult = stearing_mult_
		speed_mult = speed_mult_
		AllUpgrades.append(self )
	
	func end():
		AllUpgrades.erase(self )
	
	static func get_speed_sum():
		return AllUpgrades.map(func(efec: upgrade): return efec.speed_mult - 1).reduce(func(accum, number): return accum + number, 0) + 1
	
	static func get_steering_sum():
		return AllUpgrades.map(func(efec: upgrade): return efec.steering_mult - 1).reduce(func(accum, number): return accum + number, 0) + 1

func add(efect_name: String):
	match efect_name:
		"speed":
			upgrade.new(self , 1, 1.1)
		"steering":
			upgrade.new(self , 1.1, 1)
		_:
			push_warning("unknown upgrade : ", efect_name)

func get_speed_mult():
	return upgrade.get_speed_sum()

func get_stearing_mult():
	return upgrade.get_steering_sum()
