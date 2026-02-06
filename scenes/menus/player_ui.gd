extends Menu
class_name PlayerUI
class combo:
	static var all_combo : Array[combo] = []
	static var TotalPoints : int
	
	# public
	var root_node : Node 
	var TEXT : String 
	var combo_time : float = 1 
	var count : int = 1
	var point_value : int = 100
	
	# private 
	var timer : Timer
	var label : Label
	
	var label_size_y :float = 78
	var offset_ : Vector2 = Vector2(10 , 10)
	
	static func get_text(new_text_ : String , count_ : int) -> String:
		return new_text_ + " x " + str(count_)  
	
	func create_timer():
		if root_node == null:
			push_warning("you're trying to reset combo time on unfinished combo there is no root node set how you even want to reset timer on a node that you coudnt even create wtf arre you doing")
			return
		if timer == null:
			timer = Timer.new()
			root_node.add_child(timer)
			timer.timeout.connect(destructor)
	
	func set_timer(new_time_ : float):
		create_timer()
		timer.start(new_time_)
	
	func create_label():
		if root_node == null:
			push_warning("nooooo dont try to create label if there is no root node , : from combo class")
			return
		if label == null :
			label = Label.new()
			label.text = get_text(TEXT , count)
			label.position.x = offset_.x 
			var label_index = all_combo.find(self) 
			label.position.y =  offset_.y + label_index * label_size_y
			root_node.add_child(label)
	
	func refresh_label():
		create_label()
		label.text = get_text(TEXT , count)
		prints(label.text , label.visible , label.position , all_combo.find(self) , all_combo.size())
		var label_index = all_combo.find(self) 
		label.position.y = offset_.y + label_index * label_size_y
	
	func _init(text_ : String , time : float , point_val : int , root_node_ : Node) -> void:
		if all_combo.any(func(c : combo) : return c.TEXT == text_):
			var refresh_combo : combo = all_combo.filter(func(c : combo) : return c.TEXT == text_).back()
			refresh_combo.set_timer(time) 
			refresh_combo.count += 1
			refresh_combo.refresh_label()
		else:
			TEXT = text_
			point_value = point_val
			root_node = root_node_
			create_timer()
			create_label()
			all_combo.append(self)
			
	func destructor():
		TotalPoints += point_value * count * count
		all_combo.erase(self)
		if timer != null:
			timer.queue_free()
		if label != null:
			label.queue_free()
	
	static func get_total_points():
		return TotalPoints
	
	static func get_combo_text(i : int):
		return all_combo[i].text

func add_new_combo(text_ : String , time : float , point_val : int):
	combo.new(text_ , time , point_val , self)

func _ready() -> void:
	StopGame = false
	Open()

func _process(_delta: float) -> void:
	$point_label.text = str(combo.get_total_points()).replace("0" , "o") ### the font i used dont have 0 for some reason
