extends "res://Gates/dropdown/drop_down_menu.gd"

func set_nodes_to_enable():
	in_nodes = 1
	out_nodes = 1

var gateType = "NOT"

#used in inhereited nodes
func _check_if_type_correct():
	isCorrect = (selectedType == gateType)


