extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var crane_player: AudioStreamPlayer
var sonar_player: AudioStreamPlayer

var menu_music = preload("res://assets/Sound/menu_music.mp3")
var level_music = preload("res://assets/Sound/level_music.mp3")
var click_sound = preload("res://assets/Sound/button_click.mp3")
var pluck_sound = preload("res://assets/Sound/Pluck.mp3")
var crane_sound = preload("res://assets/Sound/crane_sound.mp3")
var sonar_sound = preload("res://assets/Sound/sonar.mp3")
var success_sound = preload("res://assets/Sound/success.mp3")

var current_music_stream = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep running when paused
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master" # Or "Music" if you have buses
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master" # Or "SFX"
	add_child(sfx_player)
	
	sonar_player = AudioStreamPlayer.new()
	sonar_player.bus = "Master"
	add_child(sonar_player)
	
	crane_player = AudioStreamPlayer.new()
	crane_player.bus = "Master"
	crane_player.stream = crane_sound
	crane_player.finished.connect(func(): crane_player.play()) # Loop crane sound
	add_child(crane_player)
	
	play_menu_music()

func _on_music_finished():
	if current_music_stream:
		music_player.play()

func play_menu_music():
	if current_music_stream == menu_music and music_player.playing:
		return
	_play_music(menu_music)

func play_level_music():
	if current_music_stream == level_music and music_player.playing:
		return
	_play_music(level_music)

func _play_music(stream):
	current_music_stream = stream
	music_player.stream = stream
	music_player.play()

func play_click():
	sfx_player.stream = click_sound
	sfx_player.play()

func play_pluck():
	sfx_player.stream = pluck_sound
	sfx_player.play()

func play_sonar():
	sonar_player.stream = sonar_sound
	sonar_player.play()

func play_success():
	sfx_player.stream = success_sound
	sfx_player.play()

func play_crane():
	if not crane_player.playing:
		crane_player.play()

func stop_crane():
	if crane_player.playing:
		crane_player.stop()

func connect_buttons(root_node: Node):
	# Helper to connect all buttons in a scene to the click sound
	for node in root_node.get_children():
		if node is Button:
			if not node.pressed.is_connected(play_click):
				node.pressed.connect(play_click)
		connect_buttons(node) # Recursive
