extends Node

@onready var road_base_preload = preload("res://assets/models/obstacles/road_piece2.tscn")
@onready var road_base_with_wall_preload = preload("res://assets/models/obstacles/road_piece_with_wall.tscn")

@export var player : Node 

@export var render_distance_z: int = 10 
@export var render_distance_x: int = 1

var floor_size : Vector3
var active_chunks: Dictionary = {}

class Chunk:
	var grid_position: Vector2i
	var node: Node3D

	func _init(_pos: Vector2i, _node: Node3D):
		grid_position = _pos
		node = _node

	func destroy():
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
	if not player: return
	update_chunks()

func update_chunks() -> void:
	var target_pos = player.ball.global_position 
	var current_grid_pos = get_grid_position(target_pos)
	for z in range(current_grid_pos.y - render_distance_z, current_grid_pos.y + render_distance_z):
		for x in range(current_grid_pos.x - render_distance_x, current_grid_pos.x + render_distance_x):
			var check_pos = Vector2i(x, z)
			
			if not active_chunks.has(check_pos):
				spawn_chunk(check_pos)
	
	cleanup_chunks(current_grid_pos)

func spawn_chunk(grid_pos: Vector2i):
	var scenes = [road_base_preload, road_base_with_wall_preload]
	var selected_scene = scenes.pick_random()
	
	var new_obj = selected_scene.instantiate()
	add_child(new_obj)
	
	var world_x = grid_pos.x * floor_size.x
	var world_z = grid_pos.y * floor_size.z
	new_obj.global_position = Vector3(world_x, 0, world_z)
	
	var new_chunk_data = Chunk.new(grid_pos, new_obj)
	active_chunks[grid_pos] = new_chunk_data

func cleanup_chunks(player_grid_pos: Vector2i):
	var chunk_keys = active_chunks.keys()
	for key in chunk_keys:
		if key.y < player_grid_pos.y - 5 or abs(key.x - player_grid_pos.x) > render_distance_x + 2:
			active_chunks[key].destroy()
			active_chunks.erase(key)


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
