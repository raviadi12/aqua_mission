extends TextureProgressBar

signal time_expired

@onready var time_label = $Label if has_node("Label") else null

@export var total_time: float = 180.0  # 3 minutes
var time_left: float

func _ready():
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
	# Add game over logic here
	get_tree().reload_current_scene()
