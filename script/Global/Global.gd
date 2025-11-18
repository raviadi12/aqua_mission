extends Node

#Global 
const SCENE_PATH : Dictionary = {
	"main_menu" = "uid://bn112riygqtb0",
	"lvl_selection" = "uid://doac12axf5utw",
	"lvl1" = "uid://dm1srs33un6cv",
	"lvl2" = "",
	"lvl3" = "",
	"lvl4" = "",
	"lvl5" = "",
	"lvl6" = "",
	"lvl7" = "",
	"lvl8" = "",
	"lvl9" = "",
	"lvl10" = "",
}

#Global Function
func change_scene_to(node) -> void:
	get_tree().change_scene_to_file(node)
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	
