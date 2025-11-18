extends Node2D

func _on_main_menu_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.main_menu)
