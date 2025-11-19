extends Node2D

var area_enter = false
var is_picking_up = false
var pickup_timer = 0.0
var pickup_delay = 3.0
var movement_threshold = 20.0  # Max velocity to allow pickup

@onready var press_E = $"Press[E]"
@onready var trash = $"."
# @onready var progress_indicator = $PickupProgress # Removed local UI
# @onready var progress_bar = $PickupProgress/ProgressBar # Removed local UI

var player: CharacterBody2D = null

func _ready():
	# Find player
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if is_picking_up:
		# Check if player is moving too fast
		if player and player.velocity.length() > movement_threshold:
			# Player moved, reset pickup
			_cancel_pickup()
			return
		
		# Continue pickup timer
		pickup_timer += delta
		
		# Update Player UI
		if player and player.has_method("update_pickup_ui"):
			player.update_pickup_ui(true, pickup_timer, pickup_delay)
		
		if pickup_timer >= pickup_delay:
			# Pickup complete
			_complete_pickup()

func _on_trash_area_area_entered(area: Area2D) -> void:
	if area.area_entered:
		press_E.visible = true
		area_enter = true
		
func _on_trash_area_area_exited(area: Area2D) -> void:
	if area.area_entered:
		press_E.visible = false
		area_enter = false
		_cancel_pickup()
		
func _input(event: InputEvent) -> void:
	if area_enter and event.is_action_pressed("Pick_up") and not is_picking_up:
		# Start pickup process
		_start_pickup()
		
func _start_pickup() -> void:
	if player and player.velocity.length() > movement_threshold:
		return  # Can't pick up while moving too fast
		
	is_picking_up = true
	pickup_timer = 0.0
	
	if player and player.has_method("update_pickup_ui"):
		player.update_pickup_ui(true, 0.0, pickup_delay)
		
	if press_E:
		press_E.visible = false
	
	AudioManager.play_crane()

func _cancel_pickup() -> void:
	is_picking_up = false
	pickup_timer = 0.0
	
	if player and player.has_method("update_pickup_ui"):
		player.update_pickup_ui(false)
		
	if press_E and area_enter:
		press_E.visible = true
	
	AudioManager.stop_crane()

func _complete_pickup() -> void:
	AudioManager.stop_crane()
	AudioManager.play_pluck()
	
	if player and player.has_method("update_pickup_ui"):
		player.update_pickup_ui(false)
		
	get_tree().queue_delete(trash)
	HoldingItem.quantity_trash += 1
