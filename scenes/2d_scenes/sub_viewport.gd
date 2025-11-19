extends SubViewport

@onready var minimap_camera: Camera2D = $MiniMapWorld/MiniMapCamera
@onready var player_icon: Sprite2D = $MiniMapWorld/PlayerIcon
@onready var minimap_world: Node2D = $MiniMapWorld

# Sonar UI (In MiniMapLayer, which is grandparent of SubViewport)
var sonar_status_rect: ColorRect
var sonar_status_label: Label
var sonar_progress: ProgressBar

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
	
	# Setup Sonar UI
	# SonarPanel is now in HUDLayer (child of MainCharacter)
	if player:
		var hud_layer = player.get_node_or_null("HUDLayer")
		if hud_layer:
			var sonar_panel = hud_layer.get_node_or_null("SonarPanel")
			if sonar_panel:
				sonar_status_rect = sonar_panel.get_node_or_null("StatusRect")
				sonar_status_label = sonar_panel.get_node_or_null("StatusLabel")
				sonar_progress = sonar_panel.get_node_or_null("ProgressBar")
				
				# Modernize Sonar Progress Bar
				if sonar_progress:
					var style_bg = StyleBoxFlat.new()
					style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
					style_bg.corner_radius_top_left = 5
					style_bg.corner_radius_top_right = 5
					style_bg.corner_radius_bottom_right = 5
					style_bg.corner_radius_bottom_left = 5
					
					var style_fill = StyleBoxFlat.new()
					style_fill.bg_color = Color(0.0, 0.8, 1.0, 1.0) # Cyan/Blue
					style_fill.corner_radius_top_left = 5
					style_fill.corner_radius_top_right = 5
					style_fill.corner_radius_bottom_right = 5
					style_fill.corner_radius_bottom_left = 5
					
					sonar_progress.add_theme_stylebox_override("background", style_bg)
					sonar_progress.add_theme_stylebox_override("fill", style_fill)
					sonar_progress.show_percentage = false

	# Setup Sonar Ring
	_setup_sonar_ring()
	_setup_background()
	_setup_player_circle()
	
	print("Minimap initialized - Player: ", player != null, " Camera: ", minimap_camera != null, " PlayerAnim: ", player_anim != null)
	if player:
		print("Player type: ", player.get_class(), " Player name: ", player.name)
	call_deferred("_spawn_trash_icons")

func _setup_player_circle():
	if player_icon:
		player_icon.texture = null # Remove sprite texture
		player_icon.visible = true
		player_icon.modulate = Color(1, 1, 1, 1)
		
		# Remove old children if any
		for child in player_icon.get_children():
			child.queue_free()
		
		# Create a Red Circle using Polygon2D (More reliable than script injection)
		var circle = Polygon2D.new()
		var radius = 40.0 # Larger as requested
		var points = PackedVector2Array()
		var segments = 32
		for i in range(segments + 1):
			var angle = i * TAU / float(segments)
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		
		circle.polygon = points
		circle.color = Color(1, 0, 0, 1) # Red
		player_icon.add_child(circle)

func _setup_background():
	# Create a sonar-style background attached to the camera so it follows the player
	if minimap_camera:
		# 1. Background Color
		var bg_rect = ColorRect.new()
		bg_rect.color = Color(0.0, 0.05, 0.0, 1.0) # Dark Green
		bg_rect.size = Vector2(4000, 4000)
		bg_rect.position = Vector2(-2000, -2000)
		bg_rect.z_index = -100
		minimap_camera.add_child(bg_rect)
		
		# 2. Radar Rings (Using Line2D)
		var max_radius = 400.0
		var steps = 4
		var color = Color(0.0, 0.4, 0.0, 0.5)
		
		for i in range(1, steps + 1):
			var radius = (max_radius / steps) * i
			var ring = Line2D.new()
			ring.width = 2.0
			ring.default_color = color
			ring.z_index = -99
			
			var points = PackedVector2Array()
			var segments = 64
			for j in range(segments + 1):
				var angle = j * TAU / float(segments)
				points.append(Vector2(cos(angle), sin(angle)) * radius)
			ring.points = points
			minimap_camera.add_child(ring)
			
		# 3. Crosshairs
		var h_line = Line2D.new()
		h_line.points = PackedVector2Array([Vector2(-max_radius, 0), Vector2(max_radius, 0)])
		h_line.width = 2.0
		h_line.default_color = color
		h_line.z_index = -99
		minimap_camera.add_child(h_line)
		
		var v_line = Line2D.new()
		v_line.points = PackedVector2Array([Vector2(0, -max_radius), Vector2(0, max_radius)])
		v_line.width = 2.0
		v_line.default_color = color
		v_line.z_index = -99
		minimap_camera.add_child(v_line)

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
	
	# Update UI
	if sonar_status_rect and sonar_status_label and sonar_progress:
		if sonar_cooldown <= 0:
			# Ready
			sonar_status_rect.color = Color(0, 1, 0) # Green
			sonar_status_label.text = "Sonar is Ready"
			sonar_progress.value = 100
		else:
			# Charging
			sonar_status_rect.color = Color(1, 0, 0) # Red
			sonar_status_label.text = "Sonar is charging"
			if sonar_cooldown_max > 0:
				sonar_progress.value = ((sonar_cooldown_max - sonar_cooldown) / sonar_cooldown_max) * 100
			else:
				sonar_progress.value = 0

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
		icon.modulate = Color(1, 1, 1, 1) # White when detected
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
	# User requirement: "If Elements starts with Trash## (trash then number) or just trash, then make it as icon, other than that, no."
	var is_trash = false
	if node.name == "Trash":
		is_trash = true
	elif node.name.begins_with("Trash"):
		# Check if the rest is a number
		var suffix = node.name.substr(5)
		if suffix.is_valid_int():
			is_trash = true
			
	if is_trash and node is Node2D and node != player:
		_create_trash_icon(node)
	
	# Recursively search children
	for child in node.get_children():
		_search_for_trash(child)

func _create_trash_icon(trash_node: Node2D) -> void:
	# Avoid duplicates
	if trash_icons.has(trash_node):
		return
		
	# Create icon for this trash (Glowing White Square)
	if minimap_world == null:
		return
	
	var icon = ColorRect.new()
	var size = 30.0
	icon.size = Vector2(size, size)
	icon.position = -Vector2(size, size) / 2.0 # Center it
	icon.color = Color(1, 1, 1, 1) # White
	icon.visible = false # Hidden by default (Sonar required)
	
	# Add a "glow" effect (optional, simple border or larger rect behind)
	# For now, just the white square as requested
	
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
