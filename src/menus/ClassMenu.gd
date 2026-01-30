extends CanvasLayer
class_name Menu

static var MenuOpened : Array[Menu] = []
var Opened : bool = false
var StopGame = true 

func Open():
	for _menu in MenuOpened:
		if _menu != null:
			_menu.Close(false)
	if MenuOpened.find(self) == -1 :
		MenuOpened.append(self)
	visible = true
	Opened = true
	if not MenuOpened.filter(func(obj : Menu) : return obj.StopGame == true).is_empty() and StopGame :
		get_tree().paused = true

func Close(EraseFromStack = true):
	visible = false
	Opened = false
	if EraseFromStack : 
		MenuOpened.erase(self)
		if MenuOpened.filter(func(obj : Menu) : return obj.StopGame == true).is_empty() : 
			if StopGame : get_tree().paused = false
		if MenuOpened.back() != null:
			MenuOpened.back().Open()

func _exit_tree() -> void:
	MenuOpened.erase(self)
