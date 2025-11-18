extends Node2D

var area_enter = false
@onready var press_E = $"Press[E]"
@onready var trash = $"."


func _on_trash_area_area_entered(area: Area2D) -> void:
	if (area.area_entered) : 
		press_E.visible = true
		area_enter = true
		
func _on_trash_area_area_exited(area: Area2D) -> void:
	if (area.area_entered) : 
		press_E.visible = false
		area_enter = false
		
func _input(event: InputEvent) -> void:
	if (area_enter and event.is_action_pressed("Pick_up")):
		get_tree().queue_delete(trash)
		HoldingItem.quantity_trash += 1
