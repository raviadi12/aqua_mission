extends CanvasLayer

@onready var title_label = $Panel/TitleLabel
@onready var summary_label = $Panel/SummaryLabel
@onready var next_button = $Panel/NextButton
@onready var menu_button = $Panel/MenuButton

func _ready():
	visible = false
	AudioManager.connect_buttons(self)
	
func show_complete(burned: int, total: int):
	visible = true
	summary_label.text = "Trash Burned: %d / %d\nOcean Cleaned!" % [burned, total]
	get_tree().paused = true

func _on_next_button_pressed():
	get_tree().paused = false
	# Logic to go to next level
	# For now, go to level selection or main menu
	Global.change_scene_to(Global.SCENE_PATH["lvl_selection"])

func _on_menu_button_pressed():
	get_tree().paused = false
	Global.change_scene_to(Global.SCENE_PATH["main_menu"])
