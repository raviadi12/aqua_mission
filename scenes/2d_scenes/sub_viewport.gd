extends SubViewport
@onready var player: Camera2D = $"../../../MainCharacter/GameCamera"
@onready var camera_2d: Camera2D = $Camera2D

func _ready() -> void:
	world_2d = get_tree().root.world_2d

func _physics_process(delta: float) -> void:
	$Camera2D.position = Vector2(player.position.x + 650, player.position.y + 450)
