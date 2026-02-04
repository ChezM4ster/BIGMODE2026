extends Node

@onready var road_base_preload = preload("res://assets/models/obstacles/road_piece2.tscn")

@export var player: Node

@export var render_distance_z: int = 10
@export var render_distance_x: int = 1

var floor_size: Vector3

class Chunk:
	static var ROAD_UNCONNECTED_PRELOAD = preload("res://assets/models/obstacles/road_piece2.tscn")
	static var ROAD_DEADEND_PRELOAD = preload("res://assets/models/obstacles/road_piece2.tscn")
	static var ROAD_BASE_PRELOAD = preload("res://assets/models/obstacles/road_piece2.tscn")
	static var ROAD_BASE_TURN = preload("res://assets/models/obstacles/road_piece2.tscn")
	static var ROAD_BASE_3_DIRECTIONS = preload("res://assets/models/obstacles/road_piece2.tscn")
	static var ROAD_BASE_ALL_DIRECTIONS = preload("res://assets/models/obstacles/road_piece2.tscn")
	
	
	static var ROAD_BASE_WALL_PRELOAD = preload("res://assets/models/obstacles/road_piece_with_wall.tscn")
	
	static var all_chunks: Array[Chunk] = []
	var direction_connect: Dictionary = {Vector2i(1, 0): false, Vector2i(0, 1): false, Vector2i(-1, 0): false, Vector2i(0, -1): false}
	
	var grid_position: Vector2i
	var Root_node: Node
	var chunk_size: Vector3
	
	var node: Node3D
	
	static func get_all_chunk_positions():
		return all_chunks.map(func(c: Chunk): return c.grid_position)
	
	func set_pice_type():
		for dir in direction_connect:
			if all_chunks.any(func(chunk: Chunk): return (chunk.grid_position == grid_position + dir) and chunk.direction_connect.get(dir)):
				direction_connect.set(dir, true)
			elif all_chunks.any(func(chunk: Chunk): return (chunk.grid_position == grid_position + dir) and !chunk.direction_connect.get(dir)):
				direction_connect.set(dir, false)
			else:
				direction_connect.set(dir, [false, true].pick_random())
	
	func get_scene_array() -> Array:
		var right = direction_connect.get(Vector2i(1, 0), false)
		var down = direction_connect.get(Vector2i(0, 1), false)
		var left = direction_connect.get(Vector2i(-1, 0), false)
		var up = direction_connect.get(Vector2i(0, -1), false)
		var connection_count = int(right) + int(down) + int(left) + int(up)
		match connection_count:
			0:
				return [ROAD_UNCONNECTED_PRELOAD]
			1:
				return [ROAD_DEADEND_PRELOAD]
			2:
				if (left and right) or (up and down):
					return [ROAD_BASE_PRELOAD]
				else:
					return [ROAD_BASE_TURN]
			3:
				return [ROAD_BASE_3_DIRECTIONS]
			4:
				return [ROAD_BASE_ALL_DIRECTIONS]
		return [ROAD_UNCONNECTED_PRELOAD]
	
	func get_scene():
		var scenes = get_scene_array()
		var selected_scene = scenes.pick_random()
		
		var new_obj = selected_scene.instantiate()
		Root_node.add_child(new_obj)
		var world_x = grid_position.x * chunk_size.x
		var world_z = grid_position.y * chunk_size.z
		new_obj.global_position = Vector3(world_x, 0, world_z)
		node = new_obj
	
	func _init(grid_position_: Vector2i, Root_: Node, chunk_size_: Vector3):
		grid_position = grid_position_
		Root_node = Root_
		chunk_size = chunk_size_
		set_pice_type()
		get_scene()
		all_chunks.append(self )
		
	func destroy():
		all_chunks.erase(self )
		if is_instance_valid(node):
			node.queue_free()

func _ready() -> void:
	var temp_piece = road_base_preload.instantiate()
	var col_shape = temp_piece.find_child("CollisionShape3D", true)
	if col_shape:
		floor_size = get_chunk_size(col_shape)
	else:
		push_error("WorldGen didnt find chunk size")
	temp_piece.queue_free()

func _process(_delta: float) -> void:
	var target_pos = player.ball.global_position
	var current_grid_pos = get_grid_position(target_pos)
	for z in range(current_grid_pos.y - render_distance_z, current_grid_pos.y + render_distance_z):
		for x in range(current_grid_pos.x - render_distance_x, current_grid_pos.x + render_distance_x):
			var check_pos = Vector2i(x, z)
			if not Chunk.get_all_chunk_positions().has(check_pos):
				Chunk.new(check_pos, self , floor_size)
	
	cleanup_chunks(current_grid_pos)

func cleanup_chunks(player_grid_pos: Vector2i):
	for chunk in Chunk.all_chunks:
		var chunk_position = chunk.grid_position
		if abs(chunk_position.y - player_grid_pos.y) > render_distance_z or abs(chunk_position.x - player_grid_pos.x) > render_distance_x:
			chunk.destroy()

func get_grid_position(pos: Vector3) -> Vector2i:
	if floor_size.x == 0 or floor_size.z == 0: return Vector2i.ZERO
	return Vector2i(round(pos.x / floor_size.x), round(pos.z / floor_size.z))

func get_chunk_size(collision_node: CollisionShape3D) -> Vector3:
	var shape = collision_node.shape
	if shape is BoxShape3D:
		return shape.size * collision_node.scale
	elif shape is ConcavePolygonShape3D or shape is ConvexPolygonShape3D:
		return shape.get_debug_mesh().get_aabb().size * collision_node.scale
	return Vector3(20, 1, 20)
