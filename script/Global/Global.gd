extends Node

#Global 
const SCENE_PATH : Dictionary = {
	"main_menu" = "uid://bn112riygqtb0",
	"lvl_selection" = "uid://doac12axf5utw",
	"lvl1" = "uid://davbutwfeku6e",
	"lvl2" = "uid://dinipiddvcki8",
	"lvl3" = "uid://bmdfiakc0kql2",
	"lvl4" = "uid://sh14dt0yf76q",
	"lvl5" = "uid://dqfi2jr6nt861",
	"lvl6" = "uid://b237quqtxusn7",
	"lvl7" = "uid://ser1cm26hghk",
	"lvl8" = "uid://c832nqcb0ujh5",
	"lvl9" = "uid://jqm13a2y0hj1",
	"lvl10" = "uid://dxmy655a6y017",
}

#Global Function
func change_scene_to(node) -> void:
	get_tree().change_scene_to_file(node)
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	
