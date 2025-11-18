extends Node2D

@onready var press_O = $"Press[O]"
var enter_area : bool = false

func _on_area_furnace_area_entered(area: Area2D) -> void:
	if (area.area_entered):
		press_O.visible = true
		enter_area = true

func _on_area_furnace_area_exited(area: Area2D) -> void:
	if (area.area_entered):
		press_O.visible = false
		enter_area = false

func _input(event: InputEvent) -> void:
	if (HoldingItem.quantity_trash > 0 and enter_area and event.is_action_pressed("use_furnace")):
		HoldingItem.quantity_trash -= 1
		HoldingItem.quantity_trash_burned += 1
		
