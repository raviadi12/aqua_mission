extends CharacterBody2D

#game object call
var knockback: Vector2 = Vector2.ZERO
var knockback_decay := 10.0  # how fast it fades away

@onready var mini_menu = $Mini_menu/Mini_menu
@onready var item_displey = $Item_displey

#character's variabel
const MaxShipsSPEED = 200.0
var acceleration = 2.0
var currentVectorSpeed = Vector2(0,0)

func _ready():
	add_to_group("player")


#Character Movement
func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("left", "right","up", "down")
	
	if direction != Vector2.ZERO:
		currentVectorSpeed += Vector2(direction.x * acceleration, direction.y * acceleration)
	else:
		currentVectorSpeed -= Vector2(acceleration, acceleration)
		currentVectorSpeed.x = max(currentVectorSpeed.x, 0)
		currentVectorSpeed.y = max(currentVectorSpeed.y, 0)

	velocity = currentVectorSpeed + knockback

	# Clamp speed
	velocity.x = clamp(velocity.x, -MaxShipsSPEED, MaxShipsSPEED)
	velocity.y = clamp(velocity.y, -MaxShipsSPEED, MaxShipsSPEED)
	
	# Move
	move_and_slide()

	# Gradually remove knockback
	knockback = knockback.move_toward(Vector2.ZERO, knockback_decay)


func _process(delta: float) -> void: 
	if HoldingItem.quantity_trash > 0 :
		item_displey.visible = true
	else :
		item_displey.visible = false

#Mini_menu button function
