extends AnimatedSprite2D

@export var base_speed: float = 30.0
@export var speed_variation: float = 20.0
@export var wander_radius: float = 250.0
@export var trigger_distance: float = 100.0
@export var damage_per_second: float = 10.0

var player: CharacterBody2D = null
var player_hitbox: Node2D = null
var spawn_position: Vector2
var time_offset: float
var speed_multiplier: float
var sine_frequency: float
var cosine_frequency: float
var sine_amplitude: float
var cosine_amplitude: float

func _ready():
	play("default")
	
	# Add audio player
	var audio = AudioStreamPlayer2D.new()
	audio.stream = load("res://assets/Sound/tornado_wind.mp3")
	audio.autoplay = true
	audio.max_distance = 800 # Adjust as needed
	audio.bus = "SFX" # Or Master
	add_child(audio)
	
	spawn_position = global_position
	
	# Randomize movement parameters for unique behavior
	time_offset = randf() * TAU
	speed_multiplier = randf_range(0.5, 1.5)
	sine_frequency = randf_range(0.3, 0.8)
	cosine_frequency = randf_range(0.4, 0.9)
	sine_amplitude = randf_range(0.6, 1.0)
	cosine_amplitude = randf_range(0.6, 1.0)
	
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_error("Player not found! Make sure MainCharacter is in 'player' group")
		return
	
	# Try to get the ship's hitbox for better knockback origin
	if player.has_node("Ship'sCollisionShape"):
		player_hitbox = player.get_node("Ship'sCollisionShape")
	else:
		player_hitbox = player  # fallback
	
	add_to_group("tornado")

func _process(delta):
	# Random wandering movement using sine and cosine
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	
	# Calculate movement direction using sine and cosine waves
	var x_movement = sin(time * sine_frequency) * sine_amplitude
	var y_movement = cos(time * cosine_frequency) * cosine_amplitude
	var movement_direction = Vector2(x_movement, y_movement).normalized()
	
	# Vary speed over time
	var current_speed = base_speed + sin(time * 0.5) * speed_variation
	current_speed *= speed_multiplier
	
	# Move
	global_position += movement_direction * current_speed * delta
	
	# Keep within wander radius from spawn
	var distance_from_spawn = global_position.distance_to(spawn_position)
	if distance_from_spawn > wander_radius:
		# Push back toward spawn
		var to_spawn = (spawn_position - global_position).normalized()
		global_position += to_spawn * current_speed * delta * 2.0
	
	# Check if near player for damage
	if player_hitbox:
		var distance_to_player = global_position.distance_to(player_hitbox.global_position)
		if distance_to_player <= trigger_distance:
			_apply_continuous_effect(delta)

func _apply_continuous_effect(delta):
	if player == null:
		return
		
	if player.has_method("take_damage"):
		player.take_damage(damage_per_second * delta)
	
	_apply_knockback_to_player()

func _apply_knockback_to_player():
	if player_hitbox == null:
		return
	
	var away_direction = (player_hitbox.global_position - global_position).normalized()
	var knockback_force = 500.0
	
	if "knockback" in player:
		player.knockback += away_direction * knockback_force
