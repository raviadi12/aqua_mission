extends Node2D

@onready var press_O = $"Press[O]"
var enter_area : bool = false
var trash_buffer : int = 0
var burn_timer = 0.0
var burn_delay = 1.0 # Time to burn one piece of trash

@onready var progress_indicator = $BurnProgress
@onready var progress_bar = $BurnProgress/ProgressBar

var player: CharacterBody2D = null

func _ready():
	if progress_indicator:
		progress_indicator.visible = true # Always visible to show progress
	if progress_bar:
		progress_bar.value = 0
		# max_value will be updated in process or when trash is counted
	
	# Find player
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	# Update max value in case it changes (e.g. level init)
	if progress_bar and Global.total_trash_in_level > 0:
		progress_bar.max_value = Global.total_trash_in_level
		progress_bar.value = HoldingItem.quantity_trash_burned
	
	# Process trash in buffer
	if trash_buffer > 0:
		Global.is_furnace_burning = true
		burn_timer += delta
		if burn_timer >= burn_delay:
			_burn_one_trash()
	else:
		Global.is_furnace_burning = false
	
	# Update UI visibility
	if press_O:
		press_O.visible = enter_area and HoldingItem.quantity_trash > 0

func _burn_one_trash():
	burn_timer = 0.0
	trash_buffer -= 1
	HoldingItem.quantity_trash_burned += 1
	print("Trash burned! Total burned: ", HoldingItem.quantity_trash_burned)

func _on_area_furnace_area_entered(area: Area2D) -> void:
	# Check if the area belongs to the player or interaction layer
	enter_area = true

func _on_area_furnace_area_exited(area: Area2D) -> void:
	enter_area = false

func _input(event: InputEvent) -> void:
	if enter_area and event.is_action_pressed("use_furnace"):
		if HoldingItem.quantity_trash > 0:
			_deposit_trash()

func _deposit_trash() -> void:
	trash_buffer += HoldingItem.quantity_trash
	HoldingItem.quantity_trash = 0
	AudioManager.play_pluck()
	print("Deposited trash. Buffer: ", trash_buffer)
