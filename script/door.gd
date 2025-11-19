extends StaticBody2D

@onready var door_body = $DoorBody

var is_open = false
var speed = 50.0     
var closed_y = 132.0    
var open_y = 190.0   

func _ready():
	closed_y = door_body.position.y
	open_y = closed_y + 100.0  
	set_process(true)

func _process(delta):
	var target_y = open_y if is_open else closed_y
	door_body.position.y = lerp(door_body.position.y, target_y, delta * 5.0)
	
	# Open door when all trash in level is burned
	if Global.total_trash_in_level > 0 and HoldingItem.quantity_trash_burned >= Global.total_trash_in_level:
		is_open = true
