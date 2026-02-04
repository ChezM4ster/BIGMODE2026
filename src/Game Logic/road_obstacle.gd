extends RigidBody3D
class_name RoadObstacle

enum ObstacleType {SLOWDOWN, OIL, EXPLOSIVES, POINTS_ONLY}

@export var obstacle_type: ObstacleType = ObstacleType.POINTS_ONLY
@export var points_value: int = 10
@export var combo_tag: String = "hit"

@export_group("Slowdown")
@export var slowdown_percent: float = 0.25 # 0.0 to 1.0

@export_group("Oil")
@export var fuel_amount: float = 10.0

@export_group("Explosives")
@export var explosives_count: int = 1

func apply_to_car(car: Node) -> void:
	match obstacle_type:
		ObstacleType.SLOWDOWN:
			print_debug("Slow the car")
		ObstacleType.OIL:
			print_debug("add oil")
		ObstacleType.EXPLOSIVES:
			print_debug("add boomboom")
		ObstacleType.POINTS_ONLY:
			pass

	if points_value > 0 and car.has_method("add_points"):
		car.call("add_points", points_value, combo_tag)
