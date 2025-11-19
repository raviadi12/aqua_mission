extends Control

func _ready():
	AudioManager.connect_buttons(self)
	
func _on_lvl_1_pressed() -> void:
	# Go to intro cutscene first for level 1
	Global.change_scene_to(Global.SCENE_PATH.cutscene_level1)

func _on_lvl_2_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl2)


func _on_lvl_3_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl3)


func _on_lvl_4_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl4)
	
func _on_lvl_5_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl5)

func _on_lvl_6_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl6)

func _on_lvl_7_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl7)
	
func _on_lvl_8_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl8)

func _on_lvl_9_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl9)

func _on_lvl_10_pressed() -> void:
	Global.change_scene_to(Global.SCENE_PATH.lvl10)
