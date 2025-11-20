extends CanvasLayer

var current_level: String = ""

func _ready():
	visible = false
	AudioManager.connect_buttons(self)
	
func show_complete(burned: int, total: int, elapsed_time: float = 0.0):
	visible = true
	
	print("Level complete - burned:", burned, "/", total, " elapsed_time:", elapsed_time)
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get node references
	var summary_label = $Panel/SummaryLabel
	var next_button = $Panel/ButtonContainer/NextButton
	
	if summary_label:
		# Format time
		var minutes = floor(elapsed_time / 60)
		var seconds = floor(fmod(elapsed_time, 60))
		var time_str = "%02d:%02d" % [minutes, seconds]
		
		var summary_text = "Sampah Dibakar: " + str(burned) + " / " + str(total) + "\n\n"
		summary_text += "Waktu: " + time_str + "\n\n"
		summary_text += "Lautan Bersih!"
		summary_label.text = summary_text
	
	get_tree().paused = true
	
	# Play success sound
	AudioManager.play_success()
	
	# Determine current level from scene
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path:
		for key in Global.SCENE_PATH:
			if Global.SCENE_PATH[key] == current_scene_path:
				current_level = key
				break
	
	# Mark level as completed and unlock next level
	if current_level.begins_with("lvl"):
		var level_num = int(current_level.substr(3))
		Global.complete_level(level_num)
	
	# Update button text based on level
	if next_button:
		if current_level == "lvl10":
			next_button.text = "Lanjutkan"  # Will go to victory cutscene
		else:
			next_button.text = "Level Berikutnya"

func _on_next_button_pressed():
	get_tree().paused = false
	
	if current_level == "lvl10":
		# Go to victory cutscene
		Global.change_scene_to(Global.SCENE_PATH["cutscene_victory"])
	elif current_level != "":
		# Go to next level
		var level_num = int(current_level.substr(3))  # Extract number from "lvl1", "lvl2", etc.
		var next_level = "lvl" + str(level_num + 1)
		
		if Global.SCENE_PATH.has(next_level):
			Global.change_scene_to(Global.SCENE_PATH[next_level])
		else:
			# No next level, go to level selection
			Global.change_scene_to(Global.SCENE_PATH["lvl_selection"])
	else:
		# Fallback
		Global.change_scene_to(Global.SCENE_PATH["lvl_selection"])

func _on_menu_button_pressed():
	get_tree().paused = false
	Global.change_scene_to(Global.SCENE_PATH["main_menu"])
