extends Control

@onready var main_menu = $"."

func _ready():
	AudioManager.connect_buttons(self)

func _on_resume_pressed() -> void:
	main_menu.visible = !main_menu.visible

func _on_restart_pressed() -> void:
	# Reset trash and furnace progress
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	Global.total_trash_in_level = 0
	Global.is_furnace_burning = false
	
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl_selection)
	
