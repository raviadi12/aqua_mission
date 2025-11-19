extends Control

@onready var needle: Line2D = $SpeedometerPanel/Needle
@onready var speed_label: Label = $SpeedometerPanel/SpeedLabel
@onready var furnace_label: Label = $FurnaceStatus/Label

# Sonar UI - Moved to MiniMapLayer
# @onready var sonar_status_rect: ColorRect = $SonarPanel/StatusRect
# @onready var sonar_status_label: Label = $SonarPanel/StatusLabel
# @onready var sonar_progress: ProgressBar = $SonarPanel/ProgressBar

var player: CharacterBody2D = null
var minimap_script = null
var max_speed: float = 200.0

# Speedometer settings
var center_position: Vector2 = Vector2(75, 75)  # Center of the gauge
var needle_length: float = 50.0
var min_angle: float = 135.0  # Starting angle (bottom-left)
var max_angle: float = 405.0   # Ending angle (bottom-right, via top)

var furnace_node: Node2D = null

func _ready():
	# Find the player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		if "MaxShipsSPEED" in player:
			max_speed = player.MaxShipsSPEED
		else:
			max_speed = 200.0
		
		# Find minimap script
		# Path: Player -> MiniMapLayer -> SubViewportContainer -> SubViewport
		var minimap_layer = player.get_node_or_null("MiniMapLayer")
		if minimap_layer:
			var container = minimap_layer.get_node_or_null("SubViewportContainer")
			if container:
				minimap_script = container.get_node_or_null("SubViewport")
	
	# Find Furnace
	var furnaces = get_tree().get_nodes_in_group("Furnace")
	if furnaces.size() > 0:
		furnace_node = furnaces[0]
	else:
		# Try finding by name in the level
		if player:
			var level = player.get_parent()
			furnace_node = level.find_child("Furnace", true, false)
			if not furnace_node:
				furnace_node = level.find_child("furnace", true, false)
	
	if not furnace_node:
		print("HUD: Furnace not found!")
	else:
		print("HUD: Furnace found at ", furnace_node.global_position)

	# Modernize Sonar Progress Bar - Moved to sub_viewport.gd
	# if sonar_progress:
	# 	...

	_setup_gauge_visuals()

func _setup_gauge_visuals():
	# Redraw Outer Circle to match the new arc
	var outer_circle = $SpeedometerPanel/OuterCircle
	if outer_circle:
		var points = PackedVector2Array()
		var radius = needle_length + 5
		var segments = 32
		for i in range(segments + 1):
			var t = float(i) / segments
			var angle_deg = lerp(min_angle, max_angle, t)
			var angle_rad = deg_to_rad(angle_deg)
			points.append(center_position + Vector2(cos(angle_rad), sin(angle_rad)) * radius)
		outer_circle.points = points
		
	# Update Marks
	_update_mark($SpeedometerPanel/MinMark, min_angle)
	_update_mark($SpeedometerPanel/MidMark, (min_angle + max_angle) / 2.0)
	_update_mark($SpeedometerPanel/MaxMark, max_angle)

func _update_mark(line_node: Line2D, angle_deg: float):
	if line_node:
		var angle_rad = deg_to_rad(angle_deg)
		var dir = Vector2(cos(angle_rad), sin(angle_rad))
		var start_pos = center_position + dir * (needle_length + 2)
		var end_pos = center_position + dir * (needle_length + 10)
		line_node.points = PackedVector2Array([start_pos, end_pos])

func _process(_delta: float) -> void:
	_update_furnace_status()
	# _update_sonar_status() # Moved to sub_viewport.gd
	
	if player == null:
		return
	
	# Get current speed
	var current_speed = player.velocity.length()
	
	# Update speed label
	if speed_label:
		speed_label.text = "%d" % current_speed
	
	# Calculate needle angle based on speed
	var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
	# Use lerp instead of lerp_angle to force the long way around (Clockwise)
	var angle_deg = lerp(min_angle, max_angle, speed_ratio)
	var angle = deg_to_rad(angle_deg)
	
	# Calculate needle end position
	var needle_end = center_position + Vector2(cos(angle), sin(angle)) * needle_length
	
	# Update needle
	needle.points[1] = needle_end

func _draw():
	pass # Drawing moved to Compass.gd

# func _update_sonar_status():
# 	if not minimap_script: return
# 	
# 	var cooldown = minimap_script.sonar_cooldown
# 	var max_cooldown = minimap_script.sonar_cooldown_max
# 	
# 	if cooldown <= 0:
# 		# Ready
# 		sonar_status_rect.color = Color(0, 1, 0) # Green
# 		sonar_status_label.text = "Sonar is Ready"
# 		sonar_progress.value = 100
# 	else:
# 		# Charging
# 		sonar_status_rect.color = Color(1, 0, 0) # Red
# 		sonar_status_label.text = "Sonar is charging"
# 		if max_cooldown > 0:
# 			sonar_progress.value = ((max_cooldown - cooldown) / max_cooldown) * 100
# 		else:

func _update_furnace_status():
	if furnace_label:
		var status = "Burning..." if Global.is_furnace_burning else "Idle"
		var burned = HoldingItem.quantity_trash_burned
		var total = Global.total_trash_in_level
		
		furnace_label.text = "Furnace: %s\n%d / %d" % [status, burned, total]
		
		if Global.is_furnace_burning:
			furnace_label.modulate = Color(1, 0.5, 0) # Orange
		elif burned >= total and total > 0:
			furnace_label.text = "Furnace: DONE\n%d / %d" % [burned, total]
			furnace_label.modulate = Color(0, 1, 0) # Green
		else:
			furnace_label.modulate = Color(1, 1, 1) # White
