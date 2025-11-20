extends CharacterBody2D

#game object call
var knockback: Vector2 = Vector2.ZERO
var knockback_decay := 10.0  # how fast it fades away

@onready var item_displey = $Item_displey
@onready var ship_anim: AnimatedSprite2D = $ShipAnimation
@onready var granular_engine = $GranularEngine
@onready var pickup_ui = $HUDLayer/PickupUI

#character's variabel
const MaxShipsSPEED = 200.0
var acceleration = 2.0
var deceleration = 5.0  # Faster deceleration for better stopping
var last_facing := "South"

var health: float = 100.0

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("player")
	# Hide pickup UI at start
	if pickup_ui:
		pickup_ui.visible = false

func update_animation():
	if ship_anim == null:
		return
	
	var direction := get_facing_direction()
	
	if velocity.length() < 10:
		ship_anim.play(_safe_anim("Idle_", direction))
	else:
		ship_anim.play(_safe_anim("Moving_", direction))

func get_facing_direction() -> String:
	if velocity.length() < 10:
		return last_facing
	
	var dir := velocity.normalized()
	var facing := ""
	var flip_needed := false
	
	# Check diagonal directions first (more specific)
	if dir.y < -0.3:  # Moving upward
		if dir.x > 0.3:
			# North-East
			facing = "North_east"
			flip_needed = false
		elif dir.x < -0.3:
			# North-West (use North_East flipped)
			facing = "North_east"
			flip_needed = true
		else:
			# North
			facing = "North"
			flip_needed = false
	elif dir.y > 0.3:  # Moving downward
		if dir.x > 0.3:
			# South-East (use South_West flipped)
			facing = "South_west"
			flip_needed = true
		elif dir.x < -0.3:
			# South-West
			facing = "South_west"
			flip_needed = false
		else:
			# South
			facing = "South"
			flip_needed = false
	else:  # Mostly horizontal
		if dir.x > 0.2:
			# East
			facing = "East"
			flip_needed = false
		elif dir.x < -0.2:
			# West (use East flipped)
			facing = "East"
			flip_needed = true
		else:
			# Not moving enough, keep last facing
			return last_facing
	
	# Apply flip and update
	ship_anim.flip_h = flip_needed
	last_facing = facing
	return facing

func _safe_anim(prefix: String, direction: String) -> String:
	var candidate := prefix + direction
	if ship_anim.sprite_frames and ship_anim.sprite_frames.has_animation(candidate):
		return candidate
	var fallback := prefix + last_facing
	if ship_anim.sprite_frames and ship_anim.sprite_frames.has_animation(fallback):
		return fallback
	return prefix + "South"


#Character Movement
func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	
	# Handle X-axis movement
	if input_dir.x != 0:
		# Accelerate in the direction of input
		velocity.x += input_dir.x * acceleration
	else:
		# Decelerate when no X input
		velocity.x = move_toward(velocity.x, 0, deceleration)
	
	# Handle Y-axis movement
	if input_dir.y != 0:
		# Accelerate in the direction of input
		velocity.y += input_dir.y * acceleration
	else:
		# Decelerate when no Y input
		velocity.y = move_toward(velocity.y, 0, deceleration)
	
	# Apply knockback
	velocity += knockback
	
	# Clamp to max speed
	velocity.x = clamp(velocity.x, -MaxShipsSPEED, MaxShipsSPEED)
	velocity.y = clamp(velocity.y, -MaxShipsSPEED, MaxShipsSPEED)
	
	move_and_slide()

	# Decay knockback
	knockback = knockback.move_toward(Vector2.ZERO, knockback_decay)

	# Update animation
	update_animation()
	
	# Update Granular Engine Physics
	if granular_engine:
		granular_engine.update_physics(velocity.length(), MaxShipsSPEED, get_process_delta_time())

func _process(_delta: float) -> void: 
	if HoldingItem.quantity_trash > 0 :
		item_displey.visible = true
	else :
		item_displey.visible = false

func update_pickup_ui(show_ui: bool, progress: float = 0.0, max_value: float = 1.0):
	if pickup_ui:
		pickup_ui.visible = show_ui
		if show_ui:
			var bar = pickup_ui.get_node("ProgressBar")
			if bar:
				bar.max_value = max_value
				bar.value = progress

#Mini_menu button function

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		die()

func die():
	print("Player died")
	
	# Find the level_init node which has the game over UI
	var level_init = get_tree().get_first_node_in_group("level_init")
	if level_init and level_init.has_method("show_game_over"):
		level_init.show_game_over(0)  # 0 = FUEL_RAN_OUT (generic death)
	else:
		# Fallback: reload scene
		HoldingItem.quantity_trash = 0
		HoldingItem.quantity_trash_burned = 0
		Global.total_trash_in_level = 0
		Global.is_furnace_burning = false
		get_tree().reload_current_scene()
