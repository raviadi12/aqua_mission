extends Panel

@onready var minute_label = $Label
@onready var second_label = $Label2
@onready var bar = $"../TextureProgressBar"

var total_time = 180.0  # 3 minutesp
var time_left = total_time
var warning_time = 30.0

func _ready():
	set_process(true)
	update_labels()

func _process(delta):
	if time_left > 0:
		time_left -= delta
		if time_left < 0:
			time_left = 0
		update_labels()
		_on_value_changed(time_left)
	

func update_labels():
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	

	
	minute_label.text = "%02d:" % minutes
	second_label.text = "%02d" % seconds

	# Change color to red if time < 30 seconds
	if time_left <= warning_time:
		second_label.add_theme_color_override("font_color", Color.RED)
		minute_label.add_theme_color_override("font_color", Color.RED)
	else:
		second_label.add_theme_color_override("font_color", Color.WHITE)
		minute_label.add_theme_color_override("font_color", Color.WHITE)


func _on_value_changed(value: float) -> void:
	time_left = time_left - 1
