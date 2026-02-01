@tool
class_name ShiftContainer
extends Container

@export var vertical_shift: float = 0.0:
	set(value):
		vertical_shift = value
		queue_sort()

@export var separation: float = 0.0:
	set(value):
		separation = value
		queue_sort()

@export_enum("right" ,"center" , "left") var alignment = 1:
	set(value):
		alignment = value
		queue_sort()


func _sort_children() -> void:
	var current_pos = Vector2.ZERO
	var container_width = size.x
	
	match alignment:
		0:
			current_pos.x = 0
		1: 
			current_pos.x = container_width  / 2
		2: 
			current_pos.x = container_width

	for child in get_children():
		if !(child is Control and child.visible):
			continue
		var child_size = child.get_combined_minimum_size()
		fit_child_in_rect(child, Rect2(current_pos, child_size))
		current_pos.x += separation
		current_pos.y += child_size.y + vertical_shift
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()
