extends Control

@onready var needle: Line2D = $SpeedometerPanel/Needle
@onready var speed_label: Label = $SpeedometerPanel/SpeedLabel
@onready var furnace_label: Label = $FurnaceStatus/Label

var player: CharacterBody2D = null
var max_speed: float = 200.0

# Speedometer settings
var center_position: Vector2 = Vector2(75, 75)  # Center of the gauge
var needle_length: float = 50.0
var min_angle: float = 135.0  # Starting angle (bottom-left)
var max_angle: float = 45.0   # Ending angle (bottom-right)

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

func _process(_delta: float) -> void:
	_update_furnace_status()
	
	if player == null:
		return
	
	# Get current speed
	var current_speed = player.velocity.length()
	
	# Update speed label
	if speed_label:
		speed_label.text = "%d" % current_speed
	
	# Calculate needle angle based on speed
	var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
	var angle = lerp_angle(deg_to_rad(min_angle), deg_to_rad(max_angle), speed_ratio)
	
	# Calculate needle end position
	var needle_end = center_position + Vector2(cos(angle), sin(angle)) * needle_length
	
	# Update needle
	needle.points[1] = needle_end

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
