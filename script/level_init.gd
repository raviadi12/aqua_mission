extends Node2D

var level_complete_ui_scene = preload("res://scenes/UI_scenes/level_complete_ui.tscn")
var game_over_ui_scene = preload("res://scenes/UI_scenes/game_over_ui.tscn")
var level_complete_ui_instance = null
var game_over_ui_instance = null
var is_level_finished = false

# This script should be attached to the Main node in each level
# It counts all trash objects at the start

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("level_init")  # Add to group so other scripts can find this
	_set_level_trash_goal()
	
	# Unlock sonar when entering level 4 or higher
	var current_scene_path = get_tree().current_scene.scene_file_path
	var file_name = current_scene_path.get_file().get_basename() # e.g. "level4"
	var level_num_str = file_name.replace("level", "") # "level4" -> "4"
	var level_num = int(level_num_str)
	
	if level_num >= 4:
		if not Global.sonar_unlocked:
			Global.sonar_unlocked = true
			Global.save_game()  # Save immediately so sonar stays unlocked
	
	# Instantiate UIs but keep them hidden (handled by the UI scripts themselves)
	level_complete_ui_instance = level_complete_ui_scene.instantiate()
	add_child(level_complete_ui_instance)
	
	game_over_ui_instance = game_over_ui_scene.instantiate()
	add_child(game_over_ui_instance)

func _process(_delta):
	if not is_level_finished:
		_check_win_condition()

func _check_win_condition():
	# Check if all trash is burned
	if Global.total_trash_in_level > 0 and HoldingItem.quantity_trash_burned >= Global.total_trash_in_level:
		_on_level_complete()

func _on_level_complete():
	is_level_finished = true
	print("Level Complete!")
	if level_complete_ui_instance:
		# Get elapsed time from timer
		var player = get_tree().get_first_node_in_group("player")
		var elapsed_time = 0.0
		if player:
			var timer_node = player.get_node_or_null("HUDLayer/TimerBar")
			if timer_node and timer_node.has_method("get_elapsed_time"):
				elapsed_time = timer_node.get_elapsed_time()
				print("DEBUG: Got elapsed time from timer: ", elapsed_time)
			else:
				print("DEBUG: Timer node not found or doesn't have get_elapsed_time()")
		
		level_complete_ui_instance.show_complete(HoldingItem.quantity_trash_burned, Global.total_trash_in_level, elapsed_time)

func _set_level_trash_goal():
	var current_scene_path = get_tree().current_scene.scene_file_path
	var file_name = current_scene_path.get_file().get_basename() # e.g. "level1"
	var level_key = file_name.replace("level", "lvl") # "level1" -> "lvl1"
	
	if Global.LEVEL_TRASH_REQ.has(level_key):
		Global.total_trash_in_level = Global.LEVEL_TRASH_REQ[level_key]
		print("Level goal set from data: ", Global.total_trash_in_level)
	else:
		# Fallback to counting if no data found
		call_deferred("_count_trash")

func _count_trash():
	var trash_count = 0
	_count_trash_recursive(self, trash_count)
	Global.total_trash_in_level = trash_count
	print("Level initialized with ", trash_count, " trash objects (counted)")

func _count_trash_recursive(node: Node, count: int) -> int:
	if node.name.begins_with("Trash") and node is Node2D:
		count += 1
	
	for child in node.get_children():
		count = _count_trash_recursive(child, count)
	
	return count

func show_game_over(reason: int):
	is_level_finished = true
	if game_over_ui_instance and game_over_ui_instance.has_method("show_game_over"):
		game_over_ui_instance.show_game_over(reason)
