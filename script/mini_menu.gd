extends Control

@onready var main_menu = $"."

func _ready():
	AudioManager.connect_buttons(self)

func _on_resume_pressed() -> void:
	main_menu.visible = !main_menu.visible

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl_selection)
	
