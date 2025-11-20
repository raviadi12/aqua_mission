extends CanvasLayer

signal confirmed
signal cancelled

func _ready():
	AudioManager.connect_buttons(self)

func _on_yes_button_pressed():
	AudioManager.play_click()
	confirmed.emit()
	queue_free()

func _on_no_button_pressed():
	AudioManager.play_click()
	cancelled.emit()
	queue_free()
