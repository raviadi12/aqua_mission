extends Camera2D

const CameraFirstLayerPosition = Vector2(0.0,0.0)
const CameraSecondLayerPosition = Vector2(1920.0,0.0)

func _on_layer_switch_advance_pressed() -> void:
	global_position = CameraSecondLayerPosition

func _on_layer_switch_back_pressed() -> void:
	global_position = CameraFirstLayerPosition
	
