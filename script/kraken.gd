extends Node2D

enum State { LURKING, TURNING_AGGRESSIVE, CHASING }

@export var detection_radius: float = 300.0
@export var lurk_radius: float = 200.0
@export var travel_time_min: float = 2.0
@export var travel_time_max: float = 4.0
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.0
@export var lurk_speed: float = 50.0
@export var chase_speed: float = 150.0
@export var tornado_avoidance_distance: float = 150.0
@export var tornado_flee_speed: float = 80.0
@export var aggressive_timeout: float = 20.0
@export var obstacle_detection_distance: float = 100.0
@export var obstacle_avoidance_angle: float = 45.0
@export var obstacle_collision_mask: int = 1
@export var search_angle_increment: float = 15.0
@export var max_search_attempts: int = 12
@export var debug_enabled: bool = false
@export var smoothing_speed: float = 5.0
@export var wall_follow_persistence: float = 2.0
@export var body_radius: float = 40.0
@export var min_body_radius: float = 20.0
@export var path_update_interval: float = 0.2
@export var max_search_depth: int = 12
@export var beam_width: int = 5
@export var sprite_offset: Vector2 = Vector2(0, -50) # Adjust this to align the sprite with the logic center (Red Circle)
@export var player_target_offset: Vector2 = Vector2(200, 0) # Offset to apply to player position when chasing/detecting

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

var current_state: State = State.LURKING
var spawn_position: Vector2
var target_position: Vector2
var movement_timer: float = 0.0
var idle_timer: float = 0.0
var is_moving: bool = false
var player: Node2D = null
var tornadoes: Array = []
var aggressive_timer: float = 0.0
var search_raycasts: Array[RayCast2D] = []
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var current_velocity_dir: Vector2 = Vector2.ZERO
var is_blocked: bool = false
var last_wall_direction: Vector2 = Vector2.ZERO
var shape_cast: ShapeCast2D = null
var query_params: PhysicsShapeQueryParameters2D = null
var debug_path_points: Array[Vector2] = []
var debug_path_radii: Array[float] = []
var debug_candidate_points: Array[Vector2] = []
var active_path: Array[Vector2] = []
var _path_update_timer: float = 0.0
var _cached_move_dir: Vector2 = Vector2.ZERO

# Logic Center is always global_position (Root)
func _get_body_center() -> Vector2:
	return global_position

func _update_positions() -> void:
	# Only offset the sprite. Everything else stays at Root (Logic Center).
	if anim:
		anim.position = sprite_offset
	if detection_area:
		detection_area.position = Vector2.ZERO
	if shape_cast:
		shape_cast.position = Vector2.ZERO

func _ready() -> void:
	print("Kraken Ready. Logic at Root. Sprite Offset: ", sprite_offset)
	spawn_position = global_position
	last_position = global_position
	
	_update_positions()
		
	anim.play("lurking")
	
	# Setup physics query for recursive pathfinding
	_setup_physics_query()
	
	# Create shapecast for obstacle detection (keep for fallback/simple checks)
	_setup_shapecast()
	
	_start_new_lurk_movement()
	
	# Connect detection area signal
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	
	# Add audio player
	var audio = AudioStreamPlayer2D.new()
	audio.name = "AngrySound"
	audio.stream = load("res://assets/Sound/kraken_angry.mp3")
	audio.bus = "SFX"
	add_child(audio)
	
	_find_tornadoes()

func _setup_physics_query() -> void:
	query_params = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = body_radius
	query_params.shape = circle
	query_params.collision_mask = obstacle_collision_mask
	query_params.collide_with_bodies = true
	query_params.collide_with_areas = false

func _setup_shapecast() -> void:
	shape_cast = ShapeCast2D.new()
	shape_cast.enabled = true
	shape_cast.position = Vector2.ZERO # Align with body center
	shape_cast.collision_mask = obstacle_collision_mask
	shape_cast.collide_with_areas = false
	shape_cast.collide_with_bodies = true
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = body_radius
	shape_cast.shape = circle_shape
	
	shape_cast.target_position = Vector2(obstacle_detection_distance, 0)
	add_child(shape_cast)

func _find_tornadoes() -> void:
	tornadoes = get_tree().get_nodes_in_group("tornado")
	print("Kraken found ", tornadoes.size(), " tornadoes to avoid")

func _process(delta: float) -> void:
	# Live update for visual offset (useful for debugging/tweaking)
	_update_positions()

	match current_state:
		State.LURKING:
			_process_lurking(delta)
		State.TURNING_AGGRESSIVE:
			_process_turning_aggressive(delta)
		State.CHASING:
			_process_chasing(delta)
	
	if debug_enabled:
		queue_redraw()

func _draw() -> void:
	if not debug_enabled:
		return
		
	# Draw candidate path (searching)
	if debug_candidate_points.size() > 0:
		for i in range(debug_candidate_points.size()):
			var pos = debug_candidate_points[i]
			var color = Color(1, 1, 0, 0.3) # Yellow for candidate
			draw_circle(to_local(pos), body_radius * 0.5, color)
			if i > 0:
				draw_line(to_local(debug_candidate_points[i-1]), to_local(pos), color, 1.0)
			else:
				draw_line(Vector2.ZERO, to_local(pos), color, 1.0)

	# Draw recursive path (active)
	if debug_path_points.size() > 0:
		for i in range(debug_path_points.size()):
			var pos = debug_path_points[i]
			var radius = body_radius
			if i < debug_path_radii.size():
				radius = debug_path_radii[i]
				
			var color = Color(0, 1, 1, 0.5) # Cyan for path
			draw_circle(to_local(pos), radius, color)
			if i > 0:
				draw_line(to_local(debug_path_points[i-1]), to_local(pos), color, 2.0)
			else:
				draw_line(Vector2.ZERO, to_local(pos), color, 2.0)
	
	# Draw current velocity direction
	if current_velocity_dir != Vector2.ZERO:
		draw_line(Vector2.ZERO, current_velocity_dir * 100, Color.BLUE, 3.0)
		
	# Draw blocked status
	if is_blocked:
		draw_circle(Vector2.ZERO, 10, Color.RED)
	
	# Draw catch radius (outline)
	draw_arc(Vector2.ZERO, 50.0, 0, TAU, 32, Color.RED, 2.0)
	# Draw logic center
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color.GREEN, 2.0)
	draw_line(Vector2(0, -10), Vector2(0, 10), Color.GREEN, 2.0)

func _process_lurking(delta: float) -> void:
	# Check for nearby tornadoes and avoid them
	var tornado_avoidance = _get_tornado_avoidance_direction()
	
	if tornado_avoidance != Vector2.ZERO:
		# Flee from tornado
		global_position += tornado_avoidance * tornado_flee_speed * delta
		return
	
	if is_moving:
		movement_timer -= delta
		if movement_timer <= 0:
			# Stop moving and start idle
			is_moving = false
			idle_timer = randf_range(idle_time_min, idle_time_max)
		else:
			# Move toward target with obstacle avoidance
			var direction = _get_movement_direction_with_avoidance(target_position, delta)
			global_position += direction * lurk_speed * delta
			
			# Check if reached target
			if _get_body_center().distance_to(target_position) < 10.0:
				is_moving = false
				idle_timer = randf_range(idle_time_min, idle_time_max)
	else:
		# Idle state
		idle_timer -= delta
		if idle_timer <= 0:
			_start_new_lurk_movement()

func _start_new_lurk_movement() -> void:
	# Pick random position within lurk_radius from spawn
	var random_angle = randf() * TAU
	var random_distance = randf() * lurk_radius
	target_position = spawn_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	
	is_moving = true
	movement_timer = randf_range(travel_time_min, travel_time_max)

func _process_turning_aggressive(delta: float) -> void:
	# Wait for animation to finish
	if anim.animation != "turning_aggresive":
		return
	
	# Check if animation finished (simple timer-based approach)
	if not anim.is_playing():
		_switch_to_chasing()

func _process_chasing(delta: float) -> void:
	if player == null:
		# Try to find player
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
	
	# Check if stuck
	stuck_timer += delta
	if stuck_timer >= 0.5:  # Check every 0.5 seconds
		var distance_moved = global_position.distance_to(last_position)
		if distance_moved < 5.0:  # If moved less than 5 pixels in 0.5 sec, considered stuck
			print("Kraken is stuck, finding alternative path")
		last_position = global_position
		stuck_timer = 0.0
	
	# Check if player is still in detection range to reset timer
	var player_target_pos = player.global_position + player_target_offset
	var distance_to_player = _get_body_center().distance_to(player_target_pos)
	if distance_to_player <= detection_radius:
		# Player still in range, reset timer
		aggressive_timer = aggressive_timeout
	else:
		# Player out of range, countdown
		aggressive_timer -= delta
		if aggressive_timer <= 0:
			# Timeout - return to lurking
			_return_to_lurking()
			return
	
	# Check for tornado avoidance even while chasing
	var tornado_avoidance = _get_tornado_avoidance_direction()
	var final_direction = Vector2.ZERO
	var speed = chase_speed
	
	if tornado_avoidance != Vector2.ZERO:
		# Prioritize avoiding tornado
		var to_player = _get_movement_direction_with_avoidance(player_target_pos, delta)
		final_direction = (tornado_avoidance * 0.7 + to_player * 0.3).normalized()
	else:
		# Chase the player with obstacle avoidance
		final_direction = _get_movement_direction_with_avoidance(player_target_pos, delta)
	
	# Smooth out the movement to prevent twitching
	current_velocity_dir = current_velocity_dir.move_toward(final_direction, smoothing_speed * delta)
	
	# If blocked, slow down to "think" / slide carefully
	if is_blocked:
		speed *= 0.5
		
	global_position += current_velocity_dir * speed * delta
	
	# Check if caught player (close enough)
	if _get_body_center().distance_to(player_target_pos) < 50.0:
		_catch_player()

func _get_movement_direction_with_avoidance(target: Vector2, delta: float) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	
	# OPTIMIZATION: First check if we have a clear straight path to the target
	# This avoids expensive pathfinding when unnecessary
	if _has_clear_path_to_target(target, space_state):
		# Clear path! Just go straight
		active_path.clear()
		debug_path_points.clear()
		debug_candidate_points.clear()
		is_blocked = false
		return (target - _get_body_center()).normalized()
	
	# Path Following Logic
	# We maintain an 'active_path' and only switch if a significantly better one is found.
	
	# 1. Update Path Progress
	if not active_path.is_empty():
		var next_point = active_path[0]
		# If we reached the next point (within body radius), pop it
		if _get_body_center().distance_to(next_point) < body_radius:
			active_path.pop_front()
	
	# 2. Periodic Path Recalculation
	_path_update_timer -= delta
	if _path_update_timer <= 0:
		_path_update_timer = path_update_interval
		
		# Check again before expensive pathfinding (target might have moved to clear view)
		if _has_clear_path_to_target(target, space_state):
			active_path.clear()
			debug_path_points.clear()
			debug_candidate_points.clear()
			is_blocked = false
			return (target - _get_body_center()).normalized()
		
		var max_depth = max_search_depth
		var step_distance = body_radius * 2.0
		
		# Determine initial direction for search to avoid hairpins
		var search_start_dir = current_velocity_dir
		if search_start_dir.length_squared() < 0.1:
			search_start_dir = (target - _get_body_center()).normalized()
		else:
			search_start_dir = search_start_dir.normalized()
		
		# Run Beam Search
		var result = _find_path_beam_search(_get_body_center(), target, max_depth, step_distance, space_state, search_start_dir)
		var candidate_path = result["path"]
		var candidate_radii = result["radii"]
		
		if not candidate_path.is_empty():
			debug_candidate_points = candidate_path # Visualize what we are thinking about
			var use_new_path = false
			
			if active_path.is_empty():
				use_new_path = true
			else:
				# Compare endpoints: Is the new path getting us closer to the target?
				var current_end_dist = active_path.back().distance_to(target)
				var new_end_dist = candidate_path.back().distance_to(target)
				
				# Switch if:
				# A) New path is significantly better (e.g. 20 pixels closer)
				# B) We are running out of path (less than 2 points left)
				# C) Current path is blocked (optional check, but beam search handles avoidance)
				
				if new_end_dist < current_end_dist - 20.0:
					use_new_path = true
				elif active_path.size() < 2:
					use_new_path = true
			
			if use_new_path:
				active_path = candidate_path
				debug_path_points = active_path # Update visuals
				debug_path_radii = candidate_radii
	
	# 3. Return Direction
	if not active_path.is_empty():
		# Path Shortcutting / Smoothing
		# Check if we can skip the immediate next point and go to a further one
		# This prevents following small zig-zags when a straight line is available
		var look_ahead_count = min(active_path.size(), 4) # Look up to 4 points ahead
		
		# Iterate backwards from the furthest point we want to check
		for i in range(look_ahead_count - 1, 0, -1):
			var target_point = active_path[i]
			# Check if we can move straight to this point
			if _has_clear_path_to_target(target_point, space_state):
				# We can take a shortcut!
				# Remove all points before this one
				for k in range(i):
					active_path.pop_front()
				break
		
		is_blocked = false
		return (active_path[0] - _get_body_center()).normalized()
	
	# 4. Fallback (if no path found)
	is_blocked = true
	
	# Simple slide logic
	var direct_dir = (target - _get_body_center()).normalized()
	shape_cast.target_position = direct_dir * obstacle_detection_distance
	shape_cast.force_shapecast_update()
	
	if shape_cast.is_colliding():
		var collision_normal = shape_cast.get_collision_normal(0)
		var along_wall = Vector2(-collision_normal.y, collision_normal.x)
		if along_wall.dot(direct_dir) < 0:
			along_wall = -along_wall
		return along_wall
		
	return direct_dir

func _has_clear_path_to_target(target: Vector2, space_state: PhysicsDirectSpaceState2D) -> bool:
	# Check if there's a direct line of sight to the target with no obstacles
	# Use raycast for quick check
	var ray_params = PhysicsRayQueryParameters2D.create(_get_body_center(), target, obstacle_collision_mask)
	var ray_result = space_state.intersect_ray(ray_params)
	
	if not ray_result.is_empty():
		return false # Something is blocking
	
	# Also check with shape cast along the path to ensure body can fit
	# Sample a few points along the path
	var distance = _get_body_center().distance_to(target)
	var samples = max(3, int(distance / (body_radius * 2.0)))
	var direction = (target - _get_body_center()).normalized()
	
	for i in range(1, samples + 1):
		var check_dist = (distance * i) / samples
		var check_pos = _get_body_center() + direction * check_dist
		
		query_params.shape.radius = body_radius
		query_params.transform = Transform2D(0, check_pos)
		var collisions = space_state.intersect_shape(query_params)
		
		if not collisions.is_empty():
			return false # Body won't fit along this path
	
	return true # Clear path!

func _find_path_beam_search(start_pos: Vector2, target: Vector2, max_depth: int, step_dist: float, space_state: PhysicsDirectSpaceState2D, initial_dir: Vector2) -> Dictionary:
	# Beam Search Implementation
	# Instead of full recursion (exponential), we keep only the best 'beam_width' candidates at each step.
	# Complexity: O(max_depth * beam_width * branches) -> Linear with depth!
	
	# Candidate structure: { "pos": Vector2, "path": Array[Vector2], "radii": Array[float], "score": float, "dir": Vector2 }
	var current_candidates = [{
		"pos": start_pos,
		"path": [] as Array[Vector2],
		"radii": [] as Array[float],
		"score": start_pos.distance_to(target),
		"dir": initial_dir # Use provided initial direction
	}]
	
	var best_completed_path: Array[Vector2] = []
	var best_completed_radii: Array[float] = []
	
	# Visited set to prevent cycles and redundant checks
	# Key: Vector2i (grid coordinate), Value: bool
	var visited_zones = {}
	var zone_size = body_radius # Resolution for visited check
	var start_key = Vector2i(floor(start_pos.x / zone_size), floor(start_pos.y / zone_size))
	visited_zones[start_key] = true
	
	# Angles to check relative to current direction
	# We restrict turning to prevent spiraling (max 90 degrees turn)
	var angles = [0.0, PI/6, -PI/6, PI/3, -PI/3, PI/2, -PI/2]
	
	for depth in range(max_depth):
		var next_candidates = []
		
		for cand in current_candidates:
			var current_pos = cand["pos"]
			var current_dir = cand["dir"]
			var current_angle = current_dir.angle()
			
			for angle_offset in angles:
				var check_angle = current_angle + angle_offset
				var check_dir = Vector2(cos(check_angle), sin(check_angle))
				var next_pos = current_pos + check_dir * step_dist
				
				# Check visited
				var zone_key = Vector2i(floor(next_pos.x / zone_size), floor(next_pos.y / zone_size))
				if visited_zones.has(zone_key):
					continue
				
				# Check collision with full size
				query_params.shape.radius = body_radius
				query_params.transform = Transform2D(0, next_pos)
				var collisions = space_state.intersect_shape(query_params)
				
				var used_radius = body_radius
				var squeeze_penalty = 0.0
				
				if not collisions.is_empty():
					# Try squeezing
					query_params.shape.radius = min_body_radius
					collisions = space_state.intersect_shape(query_params)
					if collisions.is_empty():
						used_radius = min_body_radius
						squeeze_penalty = 50.0 # Penalty for squeezing
					else:
						continue # Blocked even when squeezed
				
				# Valid step
				visited_zones[zone_key] = true
				
				var dist_to_target = next_pos.distance_to(target)
				
				# Add penalty for turning to encourage straight paths
				# 10 units of distance penalty per radian of turn
				var turn_penalty = abs(angle_offset) * 10.0
				
				# Direction to Target Penalty (Focus Oriented)
				# Penalize directions that deviate from the direct line to the target
				var dir_to_target = (target - next_pos).normalized()
				var angle_to_target = check_dir.angle_to(dir_to_target)
				var target_focus_penalty = abs(angle_to_target) * 30.0 # Strong bias towards target
				
				# Line of Sight Check (Heuristic)
				# If the direct path to the target is blocked, penalize this node.
				# This helps the algorithm prefer paths that "uncover" the target (go around corners).
				var blocked_penalty = 0.0
				var ray_params = PhysicsRayQueryParameters2D.create(next_pos, target, obstacle_collision_mask)
				var ray_result = space_state.intersect_ray(ray_params)
				
				if not ray_result.is_empty():
					blocked_penalty = 100.0
				
				var score = dist_to_target + turn_penalty + target_focus_penalty + blocked_penalty + squeeze_penalty
				
				# Create new path array
				var new_path = cand["path"].duplicate()
				new_path.append(next_pos)
				
				var new_radii = cand["radii"].duplicate()
				new_radii.append(used_radius)
				
				next_candidates.append({
					"pos": next_pos,
					"path": new_path,
					"radii": new_radii,
					"score": score, # Lower is better
					"dir": check_dir
				})
		
		if next_candidates.is_empty():
			break # Dead end for all paths
			
		# Sort by score (distance to target + penalty) ascending
		next_candidates.sort_custom(func(a, b): return a["score"] < b["score"])
		
		# Keep only top candidates (Beam Width)
		if next_candidates.size() > beam_width:
			current_candidates = next_candidates.slice(0, beam_width)
		else:
			current_candidates = next_candidates
			
	# Return the best path from the final set of candidates (deepest and closest)
	if current_candidates.size() > 0:
		return { "path": current_candidates[0]["path"], "radii": current_candidates[0]["radii"] }
		
	return { "path": [], "radii": [] }

func _get_tornado_avoidance_direction() -> Vector2:
	var avoidance_direction = Vector2.ZERO
	
	for tornado in tornadoes:
		if not is_instance_valid(tornado):
			continue
			
		var distance = _get_body_center().distance_to(tornado.global_position)
		if distance < tornado_avoidance_distance:
			# Calculate flee direction away from tornado
			var away_from_tornado = (_get_body_center() - tornado.global_position).normalized()
			# Weight by proximity (closer = stronger avoidance)
			var weight = 1.0 - (distance / tornado_avoidance_distance)
			avoidance_direction += away_from_tornado * weight
	
	return avoidance_direction.normalized() if avoidance_direction.length() > 0 else Vector2.ZERO

func _on_detection_area_body_entered(body: Node2D) -> void:
	if current_state == State.LURKING and body.is_in_group("player"):
		player = body
		_switch_to_turning_aggressive()

func _switch_to_turning_aggressive() -> void:
	current_state = State.TURNING_AGGRESSIVE
	anim.play("turning_aggresive")
	is_moving = false
	
	var audio = get_node_or_null("AngrySound")
	if audio and not audio.playing:
		audio.play()
	
	# After animation duration, switch to chasing
	# turning_aggressive has 3 frames at 5 fps = 0.6 seconds
	await get_tree().create_timer(0.6).timeout
	_switch_to_chasing()

func _switch_to_chasing() -> void:
	current_state = State.CHASING
	anim.play("aggresive")
	aggressive_timer = aggressive_timeout

func _return_to_lurking() -> void:
	print("Kraken lost interest in player, returning to lurking")
	current_state = State.LURKING
	anim.play("lurking")
	
	var audio = get_node_or_null("AngrySound")
	if audio:
		audio.stop()
		
	player = null
	_start_new_lurk_movement()

func _catch_player() -> void:
	print("Kraken caught the player! Game Over!")
	
	# Find the level_init node which has the game over UI
	var level_init = get_tree().get_first_node_in_group("level_init")
	if level_init and level_init.has_method("show_game_over"):
		level_init.show_game_over(1)  # 1 = CAUGHT_BY_KRAKEN
	else:
		# Fallback: reload scene
		get_tree().reload_current_scene()
