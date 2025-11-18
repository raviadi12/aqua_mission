extends Node

#Mainmenu_ui_control
func _on_play_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl_selection)

func _on_quit_pressed() -> void:
	get_tree().quit()
	
