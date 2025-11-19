extends Node

func _ready():
	# Try to connect buttons in the current scene (Main Menu)
	AudioManager.connect_buttons(get_tree().current_scene)

#Mainmenu_ui_control
func _on_play_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl_selection)

func _on_quit_pressed() -> void:
	get_tree().quit()
	
