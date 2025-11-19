extends TextureProgressBar

signal time_expired

@onready var time_label = $Label if has_node("Label") else null

@export var total_time: float = 180.0  # 3 minutes
var time_left: float

func _ready():
	# Determine current level key
	var current_scene_path = get_tree().current_scene.scene_file_path
	var level_key = ""
	for key in Global.SCENE_PATH:
		if Global.SCENE_PATH[key] == current_scene_path:
			level_key = key
			break
	
	# Set total_time from Global if available
	if level_key in Global.LEVEL_TIMER_REQ:
		total_time = float(Global.LEVEL_TIMER_REQ[level_key])

	time_left = total_time
	
	# Set the progress bar values directly
	max_value = total_time
	value = total_time
	
	update_label()
	set_process(true)

func _process(delta: float):
	if time_left > 0:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			_on_time_expired()
		
		# Update the progress bar value directly
		value = time_left
		
		update_label()

func get_elapsed_time() -> float:
	return total_time - time_left

func update_label():
	if time_label:
		var minutes = floor(time_left / 60)
		var seconds = floor(fmod(time_left, 60))
		time_label.text = "%02d:%02d" % [minutes, seconds]
		
		# Optional: Change color when time is running out (e.g., last 30 seconds)
		if time_left <= 30:
			time_label.modulate = Color(1, 0, 0) # Red
		else:
			time_label.modulate = Color(1, 1, 1) # White

func _on_time_expired():
	emit_signal("time_expired")
	print("Time's up!")
	# Reset trash and furnace progress
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	Global.total_trash_in_level = 0
	Global.is_furnace_burning = false
	# Add game over logic here
	get_tree().reload_current_scene()
