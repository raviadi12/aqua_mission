extends Node

# Developer settings
const DEVELOPER_MODE = false  # Set to true to unlock all levels
const FRESH_START = false  # Set to true to reset progress every time game starts

# Save file path
const SAVE_FILE = "user://save_data.json"

# Progress tracking
var completed_levels: Array = []  # Array of completed level numbers (1-10)
var highest_level_unlocked: int = 1  # Highest level player can access
var sonar_unlocked: bool = false  # Unlocked after completing level 4

#Global 
const SCENE_PATH : Dictionary = {
	"main_menu" = "res://scenes/UI_scenes/main_menu.tscn",
	"lvl_selection" = "res://scenes/UI_scenes/lvl_selection.tscn",
	"lvl1" = "res://scenes/2d_scenes/Level/level1.tscn",
	"lvl2" = "res://scenes/2d_scenes/Level/level2.tscn",
	"lvl3" = "res://scenes/2d_scenes/Level/level3.tscn",
	"lvl4" = "res://scenes/2d_scenes/Level/level4.tscn",
	"lvl5" = "res://scenes/2d_scenes/Level/level5.tscn",
	"lvl6" = "res://scenes/2d_scenes/Level/level6.tscn",
	"lvl7" = "res://scenes/2d_scenes/Level/level7.tscn",
	"lvl8" = "res://scenes/2d_scenes/Level/level8.tscn",
	"lvl9" = "res://scenes/2d_scenes/Level/level9.tscn",
	"lvl10" = "res://scenes/2d_scenes/Level/level10.tscn",
	"cutscene_level1" = "res://scenes/UI_scenes/level1_intro.tscn",
	"cutscene_victory" = "res://scenes/UI_scenes/victory_cutscene.tscn",
	"game_over" = "res://scenes/UI_scenes/game_over_ui.tscn",
}

# Level Trash Requirements
const LEVEL_TRASH_REQ : Dictionary = {
	"lvl1" = 4,
	"lvl2" = 7,
	"lvl3" = 11,
	"lvl4" = 12,
	"lvl5" = 16,
	"lvl6" = 24,
	"lvl7" = 26,
	"lvl8" = 28,
	"lvl9" = 29,
	"lvl10" = 37,
}

# Level Timer Requirements (in seconds)
const LEVEL_TIMER_REQ : Dictionary = {
	"lvl1" = 180,
	"lvl2" = 180,
	"lvl3" = 180,
	"lvl4" = 210,
	"lvl5" = 300,
	"lvl6" = 360,
	"lvl7" = 450,
	"lvl8" = 540,
	"lvl9" = 630,
	"lvl10" = 720,
}

# Popup Data System
const LEVEL_POPUP_DATA = {
	"lvl1": [
		{
			"id": "intro_1",
			"text": [
				"Selamat pagi Pemain!", 
				"Hari ini, kamu akan membersihkan lautan!", 
				"Lautan saat ini penuh dengan sampah."
			],
			"behavior": ["game_pause"],
			"position": "center",
			"trigger": {"type": "game_start"}
		},
		{
			"id": "trash_collect",
			"text": [
				"Ini adalah sampah yang harus kamu kumpulkan.",
				"Dekati sampah untuk mengambilnya."
			],
			"behavior": ["game_pause", "pan_camera", "Trash2"],
			"position": "bottom-left",
			"trigger": {"type": "after_previous", "prev_id": "intro_1"}
		},
		{
			"id": "furnace_intro",
			"text": [
				"Setelah mengumpulkan sampah, bawa ke Tungku.",
			],
			"behavior": ["game_pause", "pan_camera", "Furnace"],
			"position": "top-left",
			"trigger": {"type": "after_previous", "prev_id": "trash_collect"}
		},
		{
			"id": "furnace_intro2",
			"text": [
				"Lihat kompas untuk mengetahui arah tungku relatif terhadap kapal."
			],
			"behavior": ["highlight_ui", "Compass"],
			"position": "top-left",
			"trigger": {"type": "after_previous", "prev_id": "furnace_intro"}
		},
		{
			"id": "pyrolysis_fuel_info",
			"text": [
				"Sampah sedang diproses! Ini bukan pembakaran biasa.",
				"Biasanya tidak semua sampah bisa dibakar, tapi kita menggunakan teknologi Pirolisis.",
				"Tungku ini memilah dan mengubah sampah menjadi bahan bakar untuk kapal kita.",
				"Jadi kita membersihkan laut sekaligus mengisi energi kapal kita untuk level selanjutnya!"
			],
			"behavior": ["game_pause"],
			"position": "center",
			"trigger": {"type": "on_variable_above", "variable": "HoldingItem.quantity_trash_burned", "value": 0}
		},
		{
			"id": "trash_pickup_info",
			"text": [
				"Sekarang ketika kamu mengambil sampah, kamu bisa ambil lagi hingga tungku penuh."
			],
			"behavior": ["game_pause"],
			"position": "center",
			"trigger": {"type": "on_variable_above", "variable": "HoldingItem.quantity_trash", "value": 0}
		},
		{
			"id": "furnace_status_info",
			"text": [
				"Perhatikan indikator ini. Ini menunjukkan berapa banyak sampah yang perlu dibakar untuk lanjut ke level berikutnya."
			],
			"behavior": ["highlight_ui", "SpeedometerHUD/FurnaceStatus"],
			"position": "top-left",
			"trigger": {"type": "after_previous", "prev_id": "trash_pickup_info"}
		}
	],
	"lvl2": [
		{
			"id": "level2_intro",
			"text": [
				"Waduh, ada banyak sekali tumpukan sampah di sini!",
				"Tenang saja, kita akan fokus membersihkan sampah yang mengapung di permukaan air terlebih dahulu.",
				"Tim kapal lain akan menangani sampah yang lebih dalam.",
				"Mari kita selesaikan bagian kita!"
			],
			"behavior": ["game_pause"],
			"position": "center",
			"trigger": {"type": "game_start"}
		}
	],
	"lvl3": [
		{
			"id": "tornado_intro",
			"text": [
				"Hati-hati dengan Tornado!",
				"Hindari tornado atau kamu akan terpental."
			],
			"behavior": ["pan_camera", "Tornado"],
			"trigger": {"type": "game_start"}
		}
	],
	"lvl4": [
		{
			"id": "level4_intro",
			"text": [
				"Kita baru saja dapat kabar bahwa ada tumpukan sampah di sini yang tenggelam ke dasar laut.",
				"Untungnya, kapal kita baru saja dipasangi Sonar!",
				"Frekuensi sonar telah disetel untuk mendeteksi sampah yang tenggelam."
			],
			"behavior": ["game_pause"],
			"position": "center",
			"trigger": {"type": "game_start"}
		},
		{
			"id": "sonar_intro",
			"text": [
				"Sekarang, perhatikan sonar.", 
				"Ini akan membantumu menemukan sampah.",
				"Titik-titik putih pada sonar menunjukkan lokasi sampah.",
				"Sonar ini sudah dikalibrasi dengan frekuensi khusus agar hanya mendeteksi sampah.",
				"Tekan 'K' untuk menggunakan Sonar.",
				"Sonar memiliki cooldown. Setelah siap, kamu bisa menggunakannya lagi."
			],
			"behavior": ["highlight_ui", "SonarPanel"],
			"position": "top-right",
			"trigger": {"type": "after_previous", "prev_id": "level4_intro"}
		}
	]
}

# Level configuration
var total_trash_in_level: int = 0
var is_furnace_burning: bool = false

func _ready():
	get_tree().debug_collisions_hint = false
	
	# Fresh start mode - reset progress every time
	if FRESH_START:
		reset_progress()
		return
	
	load_game()
	
	# Developer mode - unlock all levels
	if DEVELOPER_MODE:
		highest_level_unlocked = 10
		sonar_unlocked = true
		for i in range(1, 11):
			if not completed_levels.has(i):
				completed_levels.append(i)

#Global Function
func change_scene_to(node) -> void:
	get_tree().change_scene_to_file(node)
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	total_trash_in_level = 0
	
	# Determine music based on scene key
	var key = ""
	for k in SCENE_PATH:
		if SCENE_PATH[k] == node:
			key = k
			break
	
	# Play appropriate music
	if key.begins_with("lvl") and key != "lvl_selection":
		AudioManager.play_level_music()
	elif key.begins_with("cutscene"):
		AudioManager.play_menu_music()  # Cutscenes use menu music
	else:
		AudioManager.play_menu_music()

# Save/Load System
func save_game():
	var save_data = {
		"completed_levels": completed_levels,
		"highest_level_unlocked": highest_level_unlocked,
		"sonar_unlocked": sonar_unlocked
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully")
	else:
		print("Failed to save game")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		# New game - start fresh
		completed_levels = []
		highest_level_unlocked = 1
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			completed_levels = save_data.get("completed_levels", [])
			highest_level_unlocked = save_data.get("highest_level_unlocked", 1)
			sonar_unlocked = save_data.get("sonar_unlocked", false)
			print("Game loaded successfully")
		else:
			print("Failed to parse save file")
			completed_levels = []
			highest_level_unlocked = 1
	else:
		print("Failed to load game")
		completed_levels = []
		highest_level_unlocked = 1

func complete_level(level_number: int):
	# Mark level as completed
	if not completed_levels.has(level_number):
		completed_levels.append(level_number)
	
	# Unlock next level
	if level_number < 10:
		highest_level_unlocked = max(highest_level_unlocked, level_number + 1)
	
	save_game()

func is_level_completed(level_number: int) -> bool:
	return completed_levels.has(level_number)

func is_level_unlocked(level_number: int) -> bool:
	if DEVELOPER_MODE:
		return true
	return level_number <= highest_level_unlocked

func reset_progress():
	completed_levels = []
	highest_level_unlocked = 1
	sonar_unlocked = false
	save_game()
