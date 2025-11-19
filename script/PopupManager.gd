extends Node

var active_popups: Array = []
var completed_popups: Array = []
var current_level_data: Array = []
var pause_count: int = 0

func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS

func request_pause():
	pause_count += 1
	if get_tree():
		get_tree().paused = true
		print("PopupManager: Pause requested (count: ", pause_count, ")")

func release_pause():
	pause_count -= 1
	if pause_count <= 0:
		pause_count = 0
		if get_tree():
			get_tree().paused = false
			print("PopupManager: Pause released (count: ", pause_count, ")")
	else:
		print("PopupManager: Pause still active (count: ", pause_count, ")")

var popup_scene = preload("res://scenes/UI_scenes/BubblePopup.tscn")

func _ready():
	# Determine current level
	var current_scene_path = get_tree().current_scene.scene_file_path
	var level_key = ""
	for key in Global.SCENE_PATH:
		if Global.SCENE_PATH[key] == current_scene_path:
			level_key = key
			break
	
	if level_key in Global.LEVEL_POPUP_DATA:
		current_level_data = Global.LEVEL_POPUP_DATA[level_key]
		print("PopupManager: Loaded data for ", level_key)
		_check_triggers("game_start")
	else:
		print("PopupManager: No popup data for ", level_key)

func _process(_delta):
	# Optional: Check for variable triggers here if needed
	pass

func _check_triggers(trigger_type: String, extra_data: Dictionary = {}):
	for data in current_level_data:
		var trigger = data.get("trigger", {})
		if trigger.get("type") == trigger_type:
			# Check specific conditions
			if trigger_type == "after_previous":
				if trigger.get("prev_id") == extra_data.get("prev_id"):
					_spawn_popup(data)
			elif trigger_type == "game_start":
				_spawn_popup(data)
			elif trigger_type == "on_variable_above":
				if trigger.get("variable") == extra_data.get("variable"):
					if extra_data.get("value") > trigger.get("value"):
						_spawn_popup(data)

func check_variable_trigger(variable_name: String, value: float):
	_check_triggers("on_variable_above", {"variable": variable_name, "value": value})

func _spawn_popup(data: Dictionary):
	if data["id"] in completed_popups:
		return
	
	# Defer creation to avoid "parent busy" errors during _ready
	call_deferred("_create_popup_nodes", data)

func _create_popup_nodes(data: Dictionary):
	var popup = popup_scene.instantiate()
	# Add to a CanvasLayer to ensure it's on top of everything
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # High layer
	
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(canvas)
		canvas.add_child(popup)
		
		popup.setup(data)
		popup.popup_closed.connect(_on_popup_closed.bind(canvas))
		
		active_popups.append(data["id"])
	else:
		# Cleanup if failed
		canvas.queue_free()
		popup.queue_free()

func _on_popup_closed(popup_id: String, canvas_layer: CanvasLayer):
	active_popups.erase(popup_id)
	completed_popups.append(popup_id)
	
	# Clean up the canvas layer
	canvas_layer.queue_free()
	
	# Check for chained popups
	_check_triggers("after_previous", {"prev_id": popup_id})
