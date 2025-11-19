extends Control

signal cutscene_finished

var messages: Array = []
var current_message_index: int = 0
var is_typing: bool = false
var typing_speed: float = 0.05  # seconds per character
var current_char_index: int = 0

@onready var background = $Background
@onready var text_label = $MarginContainer/VBoxContainer/TextLabel
@onready var continue_button = $MarginContainer/VBoxContainer/ContinueButton
@onready var typing_timer = $TypingTimer

var next_scene: String = ""

func _ready():
	continue_button.visible = false
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	AudioManager.connect_buttons(self)
	
	# Start showing the first message
	if messages.size() > 0:
		show_next_message()

func setup(cutscene_messages: Array, target_scene: String = ""):
	messages = cutscene_messages
	next_scene = target_scene
	current_message_index = 0

func show_next_message():
	if current_message_index >= messages.size():
		# All messages shown, proceed to next scene
		finish_cutscene()
		return
	
	var message = messages[current_message_index]
	text_label.text = ""
	current_char_index = 0
	is_typing = true
	continue_button.visible = false
	
	typing_timer.start()

func _on_typing_timer_timeout():
	if not is_typing:
		return
	
	var full_message = messages[current_message_index]
	
	if current_char_index < full_message.length():
		text_label.text += full_message[current_char_index]
		current_char_index += 1
	else:
		# Finished typing this message
		is_typing = false
		typing_timer.stop()
		continue_button.visible = true

func _on_continue_button_pressed():
	if is_typing:
		# Skip typing animation and show full text immediately
		text_label.text = messages[current_message_index]
		is_typing = false
		typing_timer.stop()
		continue_button.visible = true
	else:
		# Move to next message
		current_message_index += 1
		show_next_message()

func finish_cutscene():
	emit_signal("cutscene_finished")
	if next_scene != "":
		Global.change_scene_to(next_scene)
	else:
		queue_free()
