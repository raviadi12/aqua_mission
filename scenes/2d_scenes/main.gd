extends Node2D

@export var tornado_scene: PackedScene
@export var spawn_interval: float = 30.0
@export var spawn_radius: float = 600.0  # adjust based on your map size
@export var max_tornadoes: int = 3  # optional limit

var player: Node2D
var active_tornadoes: Array = []

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_error("Player not found! Make sure MainCharacter is in the 'player' group")
		return
	
	# Set up timer to spawn tornadoes periodically
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_spawn_tornado)
	add_child(timer)

func _on_spawn_tornado():
	if tornado_scene == null or player == null:
		return
	
	# Optional: limit number of tornadoes
	active_tornadoes = active_tornadoes.filter(func(t): return is_instance_valid(t))
	if active_tornadoes.size() >= max_tornadoes:
		return  # skip spawning if too many
	
	# Pick random position around the player
	var angle = randf() * TAU
	var offset_distance = randf_range(spawn_radius * 0.5, spawn_radius)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * offset_distance
	
	# Instantiate and position tornado
	var tornado = tornado_scene.instantiate()
	tornado.global_position = spawn_pos
	get_tree().current_scene.add_child(tornado)
	
	active_tornadoes.append(tornado)
	print("🌪️ Tornado spawned near player at ", spawn_pos)
