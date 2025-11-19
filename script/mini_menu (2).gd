extends CanvasLayer

@onready var mini_menu = $Mini_menu

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Mini_menu"):
		mini_menu.visible = !mini_menu.visible
