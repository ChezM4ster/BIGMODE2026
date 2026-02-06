extends Node

@export var ui : PlayerUI
@export var playerConrol : PlayerCar


func _process(_delta: float) -> void:
	if playerConrol.get_player_state() == playerConrol.AIR :
		ui.add_new_combo("flight" , 2 , 1)
	elif playerConrol.get_player_state() == playerConrol.DRIVE :
		ui.add_new_combo("drive" , 0.1 , 1)
	elif playerConrol.get_player_state() == playerConrol.DRIFT :
		ui.add_new_combo("drift" , 1 , 1)
	elif playerConrol.get_player_state() == playerConrol.LOCK :
		ui.add_new_combo("cool lock" , 1 , 1)
	else:
		printerr("WTF  HOW ?")
