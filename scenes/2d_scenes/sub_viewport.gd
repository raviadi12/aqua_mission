extends SubViewport

@onready var minimap_camera: Camera2D = $MiniMapWorld/MiniMapCamera
@onready var player_icon: Sprite2D = $MiniMapWorld/PlayerIcon
@onready var minimap_world: Node2D = $MiniMapWorld

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
	
	print("Minimap initialized - Player: ", player != null, " Camera: ", minimap_camera != null, " PlayerAnim: ", player_anim != null)
	if player:
		print("Player type: ", player.get_class(), " Player name: ", player.name)
	call_deferred("_spawn_trash_icons")

func _process(delta: float) -> void:
	_update_minimap()

func _update_minimap() -> void:
	if player == null or player_icon == null or minimap_camera == null:
		return
	
	# Debug output every 60 frames
	debug_counter += 1
	if debug_counter % 60 == 0:
		print("Minimap update - Player pos: ", player.global_position, " Icon pos: ", player_icon.position)
		if player_anim:
			print("  Animation: ", player_anim.animation, " Frame: ", player_anim.frame)
	
	# Update player icon position and rotation
	player_icon.position = player.global_position
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
	minimap_world.add_child(icon)
	trash_icons[trash_node] = icon

func _update_trash_icons() -> void:
	# Update positions of all trash icons
	var to_remove = []
	for trash_node in trash_icons.keys():
		if is_instance_valid(trash_node) and not trash_node.is_queued_for_deletion():
			var icon = trash_icons[trash_node]
			if is_instance_valid(icon):
				icon.position = trash_node.global_position
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
