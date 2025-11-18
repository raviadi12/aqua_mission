extends Node

#Global 
const SCENE_PATH : Dictionary = {
	"main_menu" = "uid://bn112riygqtb0",
	"lvl_selection" = "uid://doac12axf5utw",
	"lvl1" = "res://scenes/2d_scenes/level1.tscn",
	"lvl2" = "res://scenes/2d_scenes/level2.tscn",
	"lvl3" = "res://scenes/2d_scenes/level3.tscn",
	"lvl4" = "res://scenes/2d_scenes/level4.tscn",
	"lvl5" = "res://scenes/2d_scenes/level5.tscn",
	"lvl6" = "res://scenes/2d_scenes/level6.tscn",
	"lvl7" = "res://scenes/2d_scenes/level7.tscn",
	"lvl8" = "res://scenes/2d_scenes/level8.tscn",
	"lvl9" = "res://scenes/2d_scenes/level9.tscn",
	"lvl10" = "res://scenes/2d_scenes/level10.tscn",
}

#Global Function
func change_scene_to(node) -> void:
	get_tree().change_scene_to_file(node)
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	
