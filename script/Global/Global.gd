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

# Level Trash Requirements
const LEVEL_TRASH_REQ : Dictionary = {
	"lvl1" = 3,
	"lvl2" = 5,
	"lvl3" = 7,
	"lvl4" = 8,
	"lvl5" = 10,
	"lvl6" = 12,
	"lvl7" = 15,
	"lvl8" = 18,
	"lvl9" = 20,
	"lvl10" = 25,
}

# Level configuration
var total_trash_in_level: int = 0
var is_furnace_burning: bool = false

#Global Function
func change_scene_to(node) -> void:
	get_tree().change_scene_to_file(node)
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	total_trash_in_level = 0
