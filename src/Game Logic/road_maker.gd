extends Node3D
@export var roadPieces: Array[Node3D]
@export var cam: Camera3D
@export var segment_length: float = 260.0
@export var buffer: float = 50.0
@export var travel_axis: Vector3 = Vector3.FORWARD # +Z

func _ready() -> void:
	_sortroadPieces()

func _process(_delta: float) -> void:
	if cam == null or roadPieces.size() < 3:
		return

	var cam_pos: float = _axis_pos(cam.global_position)

##moves road pieces dependent on camera position
	while cam_pos > _segment_end(roadPieces[0]) - buffer:
		_recycle_back_to_front()

	while cam_pos < _segment_start(roadPieces[0]) + buffer:
		_recycle_front_to_back()

##organizes array so that the roads are in order of how they appear to the cam
func _recycle_back_to_front() -> void:
	var back: Node3D = roadPieces.pop_front() as Node3D
	var front: Node3D = roadPieces[roadPieces.size() - 1]

	back.global_position = front.global_position + travel_axis.normalized() * segment_length
	roadPieces.append(back)
func _recycle_front_to_back() -> void:
	var front: Node3D = roadPieces.pop_back() as Node3D
	var back: Node3D = roadPieces[0]

	front.global_position = back.global_position - travel_axis.normalized() * segment_length
	roadPieces.insert(0, front)
func _sortroadPieces() -> void:
	roadPieces.sort_custom(
		func(a: Node3D, b: Node3D) -> bool:
			return _axis_pos(a.global_position) < _axis_pos(b.global_position)
	)

func _axis_pos(pos: Vector3) -> float:
	return pos.dot(travel_axis.normalized())

func _segment_start(seg: Node3D) -> float:
	return _axis_pos(seg.global_position)

func _segment_end(seg: Node3D) -> float:
	return _axis_pos(seg.global_position) + segment_length
