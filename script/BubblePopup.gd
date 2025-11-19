extends Control

signal popup_closed(popup_id)

var popup_data: Dictionary
var current_page: int = 0
var pages: Array = []
var popup_id: String = ""
var applied_behaviors: Array = []
var highlighted_node: Node = null
var original_modulate: Color = Color.WHITE
var arrow_node: Polygon2D = null
var arrow_tween: Tween = null

@onready var text_label = $PanelContainer/MarginContainer/VBoxContainer/TextLabel
@onready var next_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/NextButton
@onready var overlay = $Overlay
@onready var panel_container = $PanelContainer

func setup(data: Dictionary):
	popup_data = data
	popup_id = data.get("id", "unknown")
	pages = data.get("text", [])
	current_page = 0
	
	# Apply behaviors
	var behaviors = data.get("behavior", [])
	applied_behaviors = behaviors
	_apply_behaviors(behaviors)
	
	# Apply position
	var position = data.get("position", "center")
	_apply_position(position)
	
	# Ensure nodes are ready
	if not is_node_ready():
		await ready
	
	_show_page(0)

func _show_page(index: int):
	if index < 0 or index >= pages.size():
		_close_popup()
		return
		
	current_page = index
	
	if text_label:
		text_label.text = pages[index]
	
	if next_button:
		if index == pages.size() - 1:
			next_button.text = "OK"
		else:
			next_button.text = "NEXT"

func _on_next_button_pressed():
	if current_page < pages.size() - 1:
		_show_page(current_page + 1)
	else:
		_close_popup()

func _close_popup():
	# Revert behaviors using PopupManager
	var popup_manager = get_tree().get_first_node_in_group("popup_manager")
	for b in applied_behaviors:
		if b == "game_pause":
			if popup_manager:
				popup_manager.release_pause()
			elif get_tree():
				get_tree().paused = false
				print("BubblePopup: Game unpaused (no manager)")
	
	# Restore camera with smooth tween
	if camera_node and is_instance_valid(camera_node) and original_camera_position != Vector2.ZERO:
		# Kill active tween
		if active_tween:
			active_tween.kill()
		
		var restore_tween = create_tween()
		restore_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		restore_tween.tween_property(camera_node, "position", original_camera_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		print("BubblePopup: Camera restoring to ", original_camera_position)
		# Wait for restoration to complete before closing
		await restore_tween.finished
	
	# Reset highlighted UI
	if highlighted_node and is_instance_valid(highlighted_node):
		# Restore node back to original parent
		if highlighted_node.has_meta("original_parent"):
			var original_parent = highlighted_node.get_meta("original_parent")
			var original_index = highlighted_node.get_meta("original_index", 0)
			
			if original_parent and is_instance_valid(original_parent):
				highlighted_node.reparent(original_parent)
				# Try to restore original position in parent
				original_parent.move_child(highlighted_node, original_index)
			
			highlighted_node.remove_meta("original_parent")
			highlighted_node.remove_meta("original_index")
			highlighted_node.remove_meta("original_layer")
		
		# Restore MiniMapLayer if it was modified
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var minimap_layer = player.get_node_or_null("MiniMapLayer")
			if minimap_layer and minimap_layer.has_meta("original_layer"):
				minimap_layer.layer = minimap_layer.get_meta("original_layer")
				minimap_layer.remove_meta("original_layer")
				print("BubblePopup: Restored MiniMapLayer")
			
			# Remove both highlight layers
			var highlight_layer = player.get_node_or_null("HighlightLayer")
			if highlight_layer:
				highlight_layer.queue_free()
			
			var overlay_layer = player.get_node_or_null("HighlightOverlayLayer")
			if overlay_layer:
				overlay_layer.queue_free()
	
	# Clean up arrow
	if arrow_tween:
		arrow_tween.kill()
		arrow_tween = null
	if arrow_node and is_instance_valid(arrow_node):
		arrow_node.queue_free()
		arrow_node = null
	
	emit_signal("popup_closed", popup_id)
	queue_free()

var original_camera_position: Vector2
var camera_node: Camera2D = null
var active_tween: Tween = null

func _apply_behaviors(behaviors: Array):
	var popup_manager = get_tree().get_first_node_in_group("popup_manager")
	for i in range(behaviors.size()):
		var b = behaviors[i]
		if b == "game_pause":
			if popup_manager:
				popup_manager.request_pause()
			elif get_tree():
				get_tree().paused = true
				print("BubblePopup: Game paused (no manager)")
		elif b == "highlight_ui":
			# Next element should be the node path
			if i + 1 < behaviors.size():
				var node_path = behaviors[i + 1]
				_highlight_ui_element(node_path)
				print("BubblePopup: Highlighting ", node_path)
			else:
				# Just show overlay
				overlay.visible = true
		elif b == "pan_camera":
			# Next element should be the target node name
			if i + 1 < behaviors.size():
				var target_name = behaviors[i + 1]
				# Defer camera pan to ensure all nodes are ready
				call_deferred("_pan_camera_to", target_name)

func _pan_camera_to(target_name: String):
	# Find camera
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("BubblePopup: Player not found for camera pan")
		return
	
	# Try both camera names (level1 uses "Camera2D", others use "GameCamera")
	camera_node = player.get_node_or_null("GameCamera")
	if not camera_node:
		camera_node = player.get_node_or_null("Camera2D")
	if not camera_node:
		print("BubblePopup: Camera not found (Player: ", player.name, ")")
		return
	
	# Store original position (relative to player) only on first pan
	if original_camera_position == Vector2.ZERO:
		original_camera_position = camera_node.position
	
	# Find target
	var level = player.get_parent()
	var target = level.find_child(target_name, true, false)
	if not target:
		print("BubblePopup: Target not found: ", target_name)
		return
	
	# Calculate offset to target
	var offset = target.global_position - player.global_position
	
	# Kill previous tween if exists
	if active_tween:
		active_tween.kill()
	
	# Smooth diagonal pan using Tween
	active_tween = create_tween()
	active_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	active_tween.tween_property(camera_node, "position", offset, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	print("BubblePopup: Camera panning to ", target_name)

func _highlight_ui_element(path: String):
	# Find the UI element in the player's HUD
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("BubblePopup: Player not found for highlight")
		return
	
	var hud_layer = player.get_node_or_null("HUDLayer")
	if not hud_layer:
		print("BubblePopup: HUDLayer not found")
		return
	
	highlighted_node = hud_layer.get_node_or_null(path)
	if highlighted_node and highlighted_node is CanvasItem:
		# Store original layer and parent
		highlighted_node.set_meta("original_parent", highlighted_node.get_parent())
		highlighted_node.set_meta("original_layer", hud_layer.layer if hud_layer is CanvasLayer else 0)
		
		# Create a NEW CanvasLayer BETWEEN HUD and Popup for the dark overlay only
		var overlay_layer = CanvasLayer.new()
		overlay_layer.name = "HighlightOverlayLayer"
		overlay_layer.layer = 90  # Below popup (layer 100) but above HUD
		player.add_child(overlay_layer)
		
		# Create dark overlay in this middle layer
		var dark_overlay = ColorRect.new()
		dark_overlay.name = "HighlightDarkOverlay"
		dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		dark_overlay.color = Color(0, 0, 0, 0.7)
		dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_layer.add_child(dark_overlay)
		
		# Create ANOTHER layer above overlay for the highlighted element (but still below popup)
		var highlight_layer = CanvasLayer.new()
		highlight_layer.name = "HighlightLayer"
		highlight_layer.layer = 95  # Between overlay (90) and popup (100)
		player.add_child(highlight_layer)
		
		# Move the highlighted node to the highlight layer TEMPORARILY
		var original_index = highlighted_node.get_index()
		highlighted_node.set_meta("original_index", original_index)
		
		# Reparent to highlight layer
		highlighted_node.reparent(highlight_layer)
		
		# SPECIAL CASE: If highlighting SonarPanel, also highlight the MiniMapLayer
		if path == "SonarPanel":
			var minimap_layer = player.get_node_or_null("MiniMapLayer")
			if minimap_layer:
				# Store original layer for MiniMapLayer
				minimap_layer.set_meta("original_layer", minimap_layer.layer)
				# Move MiniMapLayer to same highlight level
				minimap_layer.layer = 95
				print("BubblePopup: Also highlighting MiniMapLayer")
		
		# Determine target for arrow
		var arrow_target = highlighted_node
		
		# SPECIAL CASE: If highlighting SonarPanel, point to the MiniMap container instead (it's the main visual)
		if path == "SonarPanel":
			var minimap_layer = player.get_node_or_null("MiniMapLayer")
			if minimap_layer:
				var container = minimap_layer.get_node_or_null("SubViewportContainer")
				if container:
					arrow_target = container
					print("BubblePopup: Pointing arrow at MiniMap container instead of panel")
		
		# Create animated arrow pointing to the highlighted element
		_create_pointing_arrow(arrow_target, highlight_layer)
		
		print("BubblePopup: Highlighted node found, overlay created")
		print("BubblePopup: Highlighting ", path)
	else:
		print("BubblePopup: Could not find node at path: ", path)

func _create_pointing_arrow(target: Node, parent_layer: CanvasLayer):
	# Get viewport size for center calculation
	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2
	
	# Get target's global position (approximate center)
	var target_pos = Vector2.ZERO
	if target is Control:
		target_pos = target.global_position + target.size / 2
	elif target is Node2D:
		target_pos = target.global_position
	
	# Calculate direction from center to target
	var direction = (target_pos - center).normalized()
	
	# Create arrow as a Polygon2D (longer and more visible)
	arrow_node = Polygon2D.new()
	arrow_node.name = "PointingArrow"
	arrow_node.color = Color(1, 0.8, 0, 1)  # Orange/yellow color
	
	# Arrow shape (pointing right, we'll rotate it) - LONGER
	var arrow_length = 100  # Increased from 80
	var arrow_width = 35  # Increased from 30
	arrow_node.polygon = PackedVector2Array([
		Vector2(0, -arrow_width/2),
		Vector2(arrow_length * 0.7, -arrow_width/2),
		Vector2(arrow_length * 0.7, -arrow_width),
		Vector2(arrow_length, 0),
		Vector2(arrow_length * 0.7, arrow_width),
		Vector2(arrow_length * 0.7, arrow_width/2),
		Vector2(0, arrow_width/2)
	])
	
	# Position arrow so the TIP is close to target, not the base
	# We want the tip to be 'gap_from_target' away from the target center
	var gap_from_target = 80  # Gap between arrow tip and target center
	
	# The arrow polygon is drawn from (0,0) to (arrow_length, 0)
	# So when we position it at arrow_start, the tip is at arrow_start + direction * arrow_length
	# We want: arrow_start + direction * arrow_length = target_pos - direction * gap_from_target
	# So: arrow_start = target_pos - direction * (gap_from_target + arrow_length)
	
	# Calculate start position based on target position directly
	var offset_distance = gap_from_target + arrow_length
	var arrow_start = target_pos - direction * offset_distance
	
	# Position and rotate arrow to point at target
	arrow_node.position = arrow_start
	arrow_node.rotation = direction.angle()
	
	# Add to highlight layer
	parent_layer.add_child(arrow_node)
	
	# Animate arrow with pulsing and slight movement toward target
	arrow_tween = create_tween()
	arrow_tween.set_loops()
	arrow_tween.set_parallel(true)
	
	# Pulse scale
	arrow_tween.tween_property(arrow_node, "scale", Vector2(1.2, 1.2), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(arrow_node, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.6)
	
	# Move toward target (closer movement)
	var end_pos = arrow_start + direction * 30  # Increased movement distance
	arrow_tween.tween_property(arrow_node, "position", end_pos, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(arrow_node, "position", arrow_start, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.6)
	
	print("BubblePopup: Created pointing arrow toward ", target_pos)

func _apply_position(position: String):
	if not panel_container:
		return
	
	match position:
		"top-left":
			panel_container.anchor_left = 0.0
			panel_container.anchor_top = 0.0
			panel_container.anchor_right = 0.0
			panel_container.anchor_bottom = 0.0
			panel_container.offset_left = 20.0
			panel_container.offset_top = 20.0
			panel_container.offset_right = 420.0
			panel_container.offset_bottom = 220.0
			panel_container.grow_horizontal = 1
			panel_container.grow_vertical = 1
		"top-right":
			panel_container.anchor_left = 1.0
			panel_container.anchor_top = 0.0
			panel_container.anchor_right = 1.0
			panel_container.anchor_bottom = 0.0
			panel_container.offset_left = -420.0
			panel_container.offset_top = 20.0
			panel_container.offset_right = -20.0
			panel_container.offset_bottom = 220.0
			panel_container.grow_horizontal = 0
			panel_container.grow_vertical = 1
		"bottom-left":
			panel_container.anchor_left = 0.0
			panel_container.anchor_top = 1.0
			panel_container.anchor_right = 0.0
			panel_container.anchor_bottom = 1.0
			panel_container.offset_left = 20.0
			panel_container.offset_top = -220.0
			panel_container.offset_right = 420.0
			panel_container.offset_bottom = -20.0
			panel_container.grow_horizontal = 1
			panel_container.grow_vertical = 0
		"bottom-right":
			panel_container.anchor_left = 1.0
			panel_container.anchor_top = 1.0
			panel_container.anchor_right = 1.0
			panel_container.anchor_bottom = 1.0
			panel_container.offset_left = -420.0
			panel_container.offset_top = -220.0
			panel_container.offset_right = -20.0
			panel_container.offset_bottom = -20.0
			panel_container.grow_horizontal = 0
			panel_container.grow_vertical = 0
		"center", _:
			# Default center position (already set in scene)
			panel_container.anchor_left = 0.5
			panel_container.anchor_top = 0.5
			panel_container.anchor_right = 0.5
			panel_container.anchor_bottom = 0.5
			panel_container.offset_left = -200.0
			panel_container.offset_top = -100.0
			panel_container.offset_right = 200.0
			panel_container.offset_bottom = 100.0
			panel_container.grow_horizontal = 2
			panel_container.grow_vertical = 2
