extends Control

@export var rotation_calibration: float = 0.0 # Degrees to offset the compass
@export var furnace_target_offset: Vector2 = Vector2(-250, 0) # Offset to apply to furnace position

var player: Node2D
var furnace: Node2D

func _ready():
	# Find player and furnace
	await get_tree().process_frame
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Compass: Found player")
	else:
		print("Compass: Player not found!")
	
	var furnaces = get_tree().get_nodes_in_group("Furnace")
	if furnaces.size() > 0:
		furnace = furnaces[0]
		print("Compass: Found furnace at ", furnace.global_position)
	else:
		# Try finding by name
		if player:
			var level = player.get_parent()
			furnace = level.find_child("Furnace", true, false)
			if not furnace:
				furnace = level.find_child("furnace", true, false)
		
		if furnace:
			print("Compass: Found furnace by name at ", furnace.global_position)
		else:
			print("Compass: Furnace not found!")

func _process(_delta):
	queue_redraw()

func _draw():
	# Always draw something for debugging if requested, but for now stick to logic
	if not player or not furnace:
		# Optional: Draw a "NO SIGNAL" icon or text if missing
		return
		
	# Position: Center of the control
	var compass_center = size / 2
	var radius = 40.0
	
	# Draw Compass Background
	draw_circle(compass_center, radius, Color(0, 0, 0, 0.6))
	draw_arc(compass_center, radius, 0, TAU, 32, Color(1, 1, 1), 3.0)
	
	# Calculate direction
	var furnace_target_pos = furnace.global_position + furnace_target_offset
	var dir_vector = (furnace_target_pos - player.global_position).normalized()
	# Rotate vector by negative player rotation to align with screen
	# Apply calibration offset
	var relative_dir = dir_vector.rotated(-player.rotation + deg_to_rad(rotation_calibration))
	
	var arrow_len = radius - 10
	var arrow_end = compass_center + relative_dir * arrow_len
	
	# Draw Arrow Line
	draw_line(compass_center, arrow_end, Color(1, 0.5, 0), 4.0)
	
	# Draw Arrow Head
	var head_size = 10.0
	var angle = relative_dir.angle()
	var p1 = arrow_end + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * head_size
	var p2 = arrow_end + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * head_size
	var points = PackedVector2Array([arrow_end, p1, p2])
	draw_colored_polygon(points, Color(1, 0.5, 0))
	
	# Draw Center Dot
	draw_circle(compass_center, 5.0, Color(1, 1, 1))
