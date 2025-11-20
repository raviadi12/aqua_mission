extends CanvasLayer

enum FailureReason {
	FUEL_RAN_OUT,
	CAUGHT_BY_KRAKEN
}

var current_level: String = ""
var failure_reason: FailureReason = FailureReason.FUEL_RAN_OUT

func _ready():
	visible = false
	AudioManager.connect_buttons(self)

func show_game_over(reason: FailureReason):
	failure_reason = reason
	visible = true
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get node references
	var title_label = $Panel/TitleLabel
	var reason_label = $Panel/ReasonLabel
	var message_label = $Panel/MessageLabel
	
	# Set title
	if title_label:
		title_label.text = "KAMU KALAH!"
	
	# Set reason and message based on failure type
	if reason_label and message_label:
		match failure_reason:
			FailureReason.FUEL_RAN_OUT:
				reason_label.text = "Bahan Bakar Habis!"
				message_label.text = "Kapal kehabisan bahan bakar.\nKamu harus membakar sampah lebih cepat untuk mengisi ulang bahan bakar."
			FailureReason.CAUGHT_BY_KRAKEN:
				reason_label.text = "Tertangkap Kraken!"
				message_label.text = "Kraken menangkapmu!\nHindari Kraken dengan hati-hati di laut."
	
	get_tree().paused = true
	
	# Play failure sound
	AudioManager.play_click()
	
	# Determine current level from scene
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path:
		for key in Global.SCENE_PATH:
			if Global.SCENE_PATH[key] == current_scene_path:
				current_level = key
				break

func _on_retry_button_pressed():
	get_tree().paused = false
	
	# Reset trash and furnace progress
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	Global.total_trash_in_level = 0
	Global.is_furnace_burning = false
	
	# Reload current scene
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	get_tree().paused = false
	
	# Reset trash and furnace progress
	HoldingItem.quantity_trash = 0
	HoldingItem.quantity_trash_burned = 0
	Global.total_trash_in_level = 0
	Global.is_furnace_burning = false
	
	Global.change_scene_to(Global.SCENE_PATH["main_menu"])
