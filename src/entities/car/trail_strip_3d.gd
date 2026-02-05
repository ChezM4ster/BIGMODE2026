extends Node3D
class_name TrailStrip3D
#car
@export var target: Node3D
#point under car where trail should be left behind
@export var sample_origin: Node3D
@export var collision_mask: int = 1

@export var ray_length: float = 4.0
@export var normal_offset: float = 0.01

@export var width: float = 0.35
@export var sample_spacing: float = 0.20
@export var max_points: int = 400

@export var material: Material
@export var fade_oldest: bool = true # uses vertex color alpha
@export var uv_scale: float = 1.0 # higher = texture repeats more often

var _points: Array[Vector3] = []
var _normals: Array[Vector3] = []
var _dist: Array[float] = []
var _total_len: float = 0.0

@onready var _mesh_instance: MeshInstance3D = MeshInstance3D.new()

func _ready() -> void:
	add_child(_mesh_instance)
	_mesh_instance.mesh = ArrayMesh.new()
	_mesh_instance.material_override = material
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _physics_process(_dt: float) -> void:
	if target == null:
		return
	if sample_origin == null:
		return

	var hit := _raycast_to_ground(sample_origin.global_position)
	if hit.is_empty():
		return

	var p: Vector3 = hit.position + hit.normal.normalized() * normal_offset
	var n: Vector3 = hit.normal.normalized()

	if _points.is_empty():
		_add_point(p, n)
		_rebuild_mesh()
		return

	if p.distance_to(_points[_points.size() - 1]) >= sample_spacing:
		_add_point(p, n)
		_trim()
		_rebuild_mesh()


func clear_trail() -> void:
	_points.clear()
	_normals.clear()
	_dist.clear()
	_total_len = 0.0
	(_mesh_instance.mesh as ArrayMesh).clear_surfaces()

func _raycast_to_ground(world_pos: Vector3) -> Dictionary:
	var from := world_pos + Vector3.UP * 0.35
	var to := from + Vector3.DOWN * ray_length

	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	q.exclude = [target]
	return space.intersect_ray(q)

func _add_point(p: Vector3, n: Vector3) -> void:
	if _points.is_empty():
		_points.append(p)
		_normals.append(n)
		_dist.append(0.0)
		return

	_total_len += p.distance_to(_points[_points.size() - 1])
	_points.append(p)
	_normals.append(n)
	_dist.append(_total_len)

func _trim() -> void:
	while _points.size() > max_points:
		_points.pop_front()
		_normals.pop_front()
		_dist.pop_front()

	# Rebase distances so UVs do not explode forever.
	if _dist.size() > 0:
		var base := _dist[0]
		for i in _dist.size():
			_dist[i] -= base
		_total_len = _dist[_dist.size() - 1]

func _rebuild_mesh() -> void:
	var m := _mesh_instance.mesh as ArrayMesh
	m.clear_surfaces()

	if _points.size() < 2:
		return

	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()

	verts.resize(_points.size() * 2)
	uvs.resize(_points.size() * 2)
	cols.resize(_points.size() * 2)

	for i in _points.size():
		var p := _points[i]
		var n := _normals[i]

		# Forward direction along the trail, projected onto the ground plane.
		var f: Vector3
		if i == 0:
			f = _points[i + 1] - p
		elif i == _points.size() - 1:
			f = p - _points[i - 1]
		else:
			f = _points[i + 1] - _points[i - 1]

		f = f - n * f.dot(n)
		if f.length() < 0.0001:
			f = Vector3.FORWARD
		f = f.normalized()

		# Side vector across the ribbon.
		var s := n.cross(f).normalized()

		var left := p - s * (width * 0.5)
		var right := p + s * (width * 0.5)

		var vi := i * 2
		verts[vi] = left
		verts[vi + 1] = right

		# UVs: U along length, V across width
		var u := (_dist[i] * uv_scale)
		uvs[vi] = Vector2(u, 0.0)
		uvs[vi + 1] = Vector2(u, 1.0)

		# Optional fade: oldest is most transparent
		var a := 1.0
		if fade_oldest and _points.size() > 2:
			a = float(i) / float(_points.size() - 1)
		var c := Color(1, 1, 1, a)
		cols[vi] = c
		cols[vi + 1] = c

	# Indices for triangle strip (2 tris per segment)
	idx.resize((_points.size() - 1) * 6)
	var w := 0
	for i in _points.size() - 1:
		var a := i * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3

		# Triangle 1: a, c, b
		idx[w] = a; w += 1
		idx[w] = c; w += 1
		idx[w] = b; w += 1

		# Triangle 2: b, c, d
		idx[w] = b; w += 1
		idx[w] = c; w += 1
		idx[w] = d; w += 1

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx

	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
