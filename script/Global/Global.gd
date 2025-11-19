extends Node

#Global 
const SCENE_PATH : Dictionary = {
	"main_menu" = "res://scenes/UI_scenes/main_menu.tscn",
	"lvl_selection" = "res://scenes/2d_scenes/lvl_selection.tscn",
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
	"lvl5" = 270,
	"lvl6" = 330,
	"lvl7" = 400,
	"lvl8" = 460,
	"lvl9" = 520,
	"lvl10" = 600,
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
			"trigger": {"type": "after_previous", "prev_id": "intro_1"}
		},
		{
			"id": "trash_collect",
			"text": [
				"Ini adalah sampah yang harus kamu kumpulkan.",
				"Dekati sampah untuk mengambilnya."
			],
			"behavior": ["game_pause", "pan_camera", "Trash2"],
			"position": "bottom-left",
			"trigger": {"type": "after_previous", "prev_id": "sonar_intro"}
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
			"id": "pyrolysis_explanation",
			"text": [
				"Tungku ini mengubah sampah menjadi bahan bakar melalui pirolisis.",
				"Pirolisis adalah cara ramah lingkungan untuk daur ulang sampah.",
				"Tungku dapat memilah plastik dan non-plastik secara otomatis.",
				"Jadi kamu tidak perlu khawatir tentang pemilahan!"
			],
			"behavior": ["game_pause"],
			"position": "bottom-right",
			"trigger": {"type": "after_previous", "prev_id": "furnace_intro2"}
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
				"Untungnya, sonar kita sudah disetel ulang untuk area ini.",
				"Frekuensi sonar telah ditingkatkan agar dapat mendeteksi sampah yang tenggelam.",
				"Kamu bisa melihatnya di peta sonar seperti biasa. Selamat bekerja!"
			],
			"behavior": ["game_pause"],
			"position": "center",
			"trigger": {"type": "game_start"}
		}
	]
}

# Level configuration
var total_trash_in_level: int = 0
var is_furnace_burning: bool = false

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
