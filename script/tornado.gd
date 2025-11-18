extends Sprite2D

@export var move_speed: float = 20.0
@export var trigger_distance: float = 100.0
@export var damage_per_second: float = 10.0

var player: CharacterBody2D = null
var player_hitbox: Node2D = null
var logic_triggered: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_error("Player not found! Make sure MainCharacter is in 'player' group")
		return
	
	# Try to get the ship's hitbox for better knockback origin
	if player.has_node("Ship'sCollisionShape"):
		player_hitbox = player.get_node("Ship'sCollisionShape")
	else:
		player_hitbox = player  # fallback
	
func _process(delta):
	if player == null:
		return
	
	var direction = (player_hitbox.global_position - global_position).normalized()
	var distance = global_position.distance_to(player_hitbox.global_position)
	
	global_position += direction * move_speed * delta
	
	if distance <= trigger_distance and not logic_triggered:
		_on_near_player()
		logic_triggered = true
	
	if distance > trigger_distance:
		logic_triggered = false

func _on_near_player():
	print("🌪️ Tornado reached the player!")
	
	if player.has_method("take_damage"):
		player.take_damage(damage_per_second)
	
	_apply_knockback_to_player()

func _apply_knockback_to_player():
	if player_hitbox == null:
		return
	
	var away_direction = (player_hitbox.global_position - global_position).normalized()
	var knockback_force = 500.0
	
	if "knockback" in player:
		player.knockback += away_direction * knockback_force

func _physics_process(delta):
	if player == null:
		return
	
	var distance = global_position.distance_to(player_hitbox.global_position)
	
	if distance <= trigger_distance:
		_apply_continuous_effect(delta)

func _apply_continuous_effect(delta):
	if player.has_method("take_damage"):
		player.take_damage(damage_per_second * delta)
