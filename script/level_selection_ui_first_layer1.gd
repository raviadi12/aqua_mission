extends Control

func _ready():
	AudioManager.connect_buttons(self)
	_update_level_locks()

func _update_level_locks():
	# Check all possible level buttons (works for both layers)
	for i in range(1, 11):
		var button_name = "Lvl" + str(i)
		if has_node(button_name):
			var button = get_node(button_name)
			if Global.is_level_unlocked(i):
				button.disabled = false
				button.modulate = Color(1, 1, 1, 1)  # Full brightness
			else:
				button.disabled = true
				button.modulate = Color(0.5, 0.5, 0.5, 0.6)  # Dimmed and grayed out
	
func _on_lvl_1_pressed() -> void:
	# Skip cutscene if level 1 already completed
	if Global.is_level_completed(1):
		Global.change_scene_to(Global.SCENE_PATH.lvl1)
	else:
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
