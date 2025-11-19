extends SubViewport

@onready var minimap_camera: Camera2D = $MiniMapWorld/MiniMapCamera
@onready var player_icon: Sprite2D = $MiniMapWorld/PlayerIcon
@onready var minimap_world: Node2D = $MiniMapWorld

@export var icon_offset: Vector2 = Vector2(25, 0) # Adjust to fix alignment
@export var trash_offset: Vector2 = Vector2.ZERO # Calibrate trash position
@export var map_scale: float = 1.0 # Calibrate map scale if needed

# Sonar Variables
var is_pinging: bool = false
var ping_radius: float = 0.0
var ping_speed: float = 400.0
var max_ping_radius: float = 1500.0
var sonar_ring: Line2D
var trash_visibility_timers: Dictionary = {} # { trash_node: time_left }
var trash_reveal_time: float = 5.0

# Cooldown
var sonar_cooldown: float = 0.0
var sonar_cooldown_max: float = 10.0 # 10 seconds cooldown

var trash_icons: Dictionary = {}
var player: CharacterBody2D
var player_anim: AnimatedSprite2D
var debug_counter: int = 0

func _ready() -> void:
	transparent_bg = false
	if minimap_camera:
		minimap_camera.enabled = true
	
	# The SubViewport is inside the player, so we go up to the player
	# SubViewport -> SubViewportContainer -> MiniMapLayer -> MainCharacter
	player = get_parent().get_parent().get_parent()
	
	# Get player's animated sprite
	if player:
		player_anim = player.get_node_or_null("ShipAnimation")
	
	# Setup Sonar Ring
	_setup_sonar_ring()
	_setup_background()
	
	print("Minimap initialized - Player: ", player != null, " Camera: ", minimap_camera != null, " PlayerAnim: ", player_anim != null)
	if player:
		print("Player type: ", player.get_class(), " Player name: ", player.name)
	call_deferred("_spawn_trash_icons")

func _setup_background():
	# Create a dark green background with grid lines
	var bg = Node2D.new()
	bg.z_index = -10 # Ensure it's behind everything
	bg.script = GDScript.new()
	bg.script.source_code = """
extends Node2D
func _draw():
	# Draw Background
	draw_rect(Rect2(-2000, -2000, 4000, 4000), Color(0.0, 0.1, 0.0, 1.0)) # Ultra dark green
	
	# Draw Grid
	var grid_size = 100
	var color = Color(0.0, 0.3, 0.0, 0.5) # Faint green lines
	for x in range(-20, 20):
		draw_line(Vector2(x * grid_size, -2000), Vector2(x * grid_size, 2000), color, 2.0)
	for y in range(-20, 20):
		draw_line(Vector2(-2000, y * grid_size), Vector2(2000, y * grid_size), color, 2.0)
"""
	if minimap_world:
		minimap_world.add_child(bg)
		# Force redraw
		bg.queue_redraw()

func _setup_sonar_ring():
	sonar_ring = Line2D.new()
	sonar_ring.width = 4.0
	sonar_ring.default_color = Color(0, 1, 0, 0.6) # Green, semi-transparent
	sonar_ring.visible = false
	sonar_ring.closed = true
	
	# We will update points dynamically instead of scaling the node
	# to avoid line width scaling issues
	
	if minimap_world:
		minimap_world.add_child(sonar_ring)

func _process(delta: float) -> void:
	_update_minimap()
	_process_sonar(delta)

func _process_sonar(delta: float):
	# Cooldown
	if sonar_cooldown > 0:
		sonar_cooldown -= delta
	
	# Start Ping
	if Input.is_physical_key_pressed(KEY_K) and not is_pinging and sonar_cooldown <= 0:
		is_pinging = true
		ping_radius = 0.0
		sonar_cooldown = sonar_cooldown_max
		sonar_ring.visible = true
		AudioManager.play_sonar()
	
	# Update Ping
	if is_pinging:
		ping_radius += ping_speed * delta
		
		if ping_radius >= max_ping_radius:
			is_pinging = false
			sonar_ring.visible = false
		else:
			# Update Ring Transform
			if player:
				sonar_ring.position = player.global_position
				# Update points to match radius
				_update_ring_points(ping_radius)
			
			# Check for trash collisions
			# We check a ring of thickness 'ping_speed * delta'
			for trash in trash_icons.keys():
				if not is_instance_valid(trash): continue
				
				var dist = player.global_position.distance_to(trash.global_position)
				# Check if the wave front just passed the trash
				if dist < ping_radius and dist > ping_radius - (ping_speed * delta * 2.0):
					_reveal_trash(trash)
	
	# Update Visibility Timers
	var to_hide = []
	for trash in trash_visibility_timers.keys():
		trash_visibility_timers[trash] -= delta
		if trash_visibility_timers[trash] <= 0:
			to_hide.append(trash)
	
	for trash in to_hide:
		trash_visibility_timers.erase(trash)
		if trash_icons.has(trash) and is_instance_valid(trash_icons[trash]):
			trash_icons[trash].visible = false
			trash_icons[trash].modulate.a = 0.0 # Ensure invisible

func _update_ring_points(radius: float):
	var points = PackedVector2Array()
	var segments = 64
	for i in range(segments + 1):
		var angle = i * TAU / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	sonar_ring.points = points

func _reveal_trash(trash):
	if trash_icons.has(trash) and is_instance_valid(trash_icons[trash]):
		var icon = trash_icons[trash]
		icon.visible = true
		icon.modulate = Color(1, 0, 0, 1) # Red when detected
		trash_visibility_timers[trash] = trash_reveal_time

func _update_minimap() -> void:
	if player == null or player_icon == null or minimap_camera == null:
		return
	
	# Debug output every 60 frames
	debug_counter += 1
	if debug_counter % 60 == 0:
		# print("Minimap update - Player pos: ", player.global_position, " Icon pos: ", player_icon.position)
		pass
	
	# Update player icon position and rotation
	# Apply Offset
	player_icon.position = player.global_position + icon_offset.rotated(player.rotation)
	player_icon.rotation = player.rotation
	
	# Update player icon texture to match current animation frame
	if player_anim and player_anim.sprite_frames:
		var current_texture = player_anim.sprite_frames.get_frame_texture(player_anim.animation, player_anim.frame)
		if current_texture and current_texture != player_icon.texture:
			player_icon.texture = current_texture
	
	# Center camera on player
	minimap_camera.position = player.global_position
	
	# Update trash icons
	_update_trash_icons()

func _spawn_trash_icons() -> void:
	if player == null:
		return
	
	# Find all trash objects in the scene by searching the level root
	var level_root = player.get_parent()
	if level_root == null:
		return
	
	# Search for all children with "Trash" in their name
	_search_for_trash(level_root)
	
	print("Minimap: Found ", trash_icons.size(), " trash objects")

func _search_for_trash(node: Node) -> void:
	# Check if this node is a trash object
	if node.name.begins_with("Trash") and node is Node2D and node != player:
		_create_trash_icon(node)
	
	# Recursively search children
	for child in node.get_children():
		_search_for_trash(child)

func _create_trash_icon(trash_node: Node2D) -> void:
	# Avoid duplicates
	if trash_icons.has(trash_node):
		return
		
	# Load trash texture
	var trash_sprite = trash_node.get_node_or_null("Sprite2D")
	if trash_sprite == null or minimap_world == null:
		return
	
	# Create icon for this trash
	var icon = Sprite2D.new()
	icon.texture = trash_sprite.texture
	icon.scale = Vector2(0.5, 0.5)  # Smaller on minimap
	icon.modulate = Color(0.8, 0.8, 0.8, 1.0)  # Slightly dimmed
	icon.visible = false # Hidden by default (Sonar required)
	minimap_world.add_child(icon)
	trash_icons[trash_node] = icon

func _update_trash_icons() -> void:
	# Update positions of all trash icons
	var to_remove = []
	for trash_node in trash_icons.keys():
		if is_instance_valid(trash_node) and not trash_node.is_queued_for_deletion():
			var icon = trash_icons[trash_node]
			if is_instance_valid(icon):
				# Apply calibration
				icon.position = trash_node.global_position * map_scale + trash_offset
		else:
			# Trash was collected, remove icon
			to_remove.append(trash_node)
	
	# Clean up removed trash
	for trash_node in to_remove:
		if trash_icons.has(trash_node):
			var icon = trash_icons[trash_node]
			if is_instance_valid(icon):
				icon.queue_free()
			trash_icons.erase(trash_node)
