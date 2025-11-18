extends CharacterBody2D

#game object call
var knockback: Vector2 = Vector2.ZERO
var knockback_decay := 10.0  # how fast it fades away

@onready var mini_menu = $Mini_menu/Mini_menu
@onready var item_displey = $Item_displey
@onready var ship_anim: AnimatedSprite2D = $ShipAnimation


#character's variabel
const MaxShipsSPEED = 200.0
var acceleration = 2.0
var currentVectorSpeed = Vector2(0,0)

func _ready():
	add_to_group("player")

func update_animation():
	# Very small movement → idle
	if velocity.length() < 10:
		# pick last direction you were facing (optional)
		ship_anim.play("Idle_" + get_facing_direction())
		return

	# Moving → play movement animation
	ship_anim.play("Moving_" + get_facing_direction())

func get_facing_direction() -> String:
	var dir = velocity.normalized()

	# Horizontal / vertical threshold
	if dir.y < -0.5:
		if dir.x > 0.5: return "North_East"
		elif dir.x < -0.5: return "North_West"
		else: return "North"
	elif dir.y > 0.5:
		if dir.x > 0.5: return "South_East"
		elif dir.x < -0.5: return "South_West"
		else: return "South"
	else:
		if dir.x > 0: return "East"
		elif dir.x < 0: return "West"
		else: return "South"  # fallback


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

	velocity.x = clamp(velocity.x, -MaxShipsSPEED, MaxShipsSPEED)
	velocity.y = clamp(velocity.y, -MaxShipsSPEED, MaxShipsSPEED)
	
	move_and_slide()

	knockback = knockback.move_toward(Vector2.ZERO, knockback_decay)

	# ← NEW: update animation here
	update_animation()



func _process(delta: float) -> void: 
	if HoldingItem.quantity_trash > 0 :
		item_displey.visible = true
	else :
		item_displey.visible = false

#Mini_menu button function
