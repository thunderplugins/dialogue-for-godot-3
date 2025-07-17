extends Node

# Signals
signal showed_message(message, character_number)
signal made_choice(choice, message)

# Exported Variables
export(int, "Subtitle", "Text Box") var style = 0

#@export_group("Settings")
export var show_name: bool = true
export var typing_animation: bool = true
#@export_subgroup("Subtitle")
export var auto_skip: bool = false
#@export_subgroup("Text Box")
export var show_avatar_: bool = true
export var swap_speaker: bool = false

#@export_group("Characters")
#@export_subgroup("First Character")
export var name_: String
export(Color) var name_color_ = Color(1,1,1)
export var avatar_: Texture
#@export_subgroup("Second Character")
export var name__: String
export(Color) var name_color__ = Color(1,1,1)
export var avatar__: Texture

# Reference Variables
onready var timer = $Timer
onready var click_detector = $click_detector

onready var subtitles = $VBoxContainer/Subtitles
onready var subtitles_name = $VBoxContainer/Subtitles/Label
onready var subtitles_message = $VBoxContainer/Subtitles/Label2
onready var subtitles_bar = $VBoxContainer/ProgressBar
onready var choices_grid = $VBoxContainer/GridContainer

onready var text_boxes = $TextBoxes/HBoxContainer
onready var text_boxes_content = $TextBoxes/HBoxContainer/VBoxContainer
onready var text_boxes_name = $TextBoxes/HBoxContainer/VBoxContainer/Label
onready var text_boxes_message = $TextBoxes/HBoxContainer/VBoxContainer/Label2
onready var text_boxes_avatar = $TextBoxes/HBoxContainer/TextureRect

# Functional Variables
var separator = ";"
var messages: PoolStringArray = []
var message_position = -1
var message_timeouts = []

var selecting_choice = {
	"condition": false,
	"dialogue": {}
}

var tween

# Processing
func _ready() -> void:
	refresh()

func start(chosen_dialogue: String):
	set_physics_process(true)
	if style == 0:
		$VBoxContainer.show()
	elif style == 1:
		$TextBoxes.show()
	click_detector.show()
	
	# Getting the messages dialogue
	if not get_node_or_null(chosen_dialogue):
		push_error("Error: Invalid dialogue provided.")
	else:
		messages = get_node(chosen_dialogue).messages
		
		# Getting the message timeouts saved in an array
		for dialogue in messages:
			var dialogue_parts = dialogue.split(separator)
			message_timeouts.append(int(dialogue_parts[2]))
			
		# Applying the settings
		if style == 0:
			if not show_name:
				subtitles_name.hide()
				
			if auto_skip:
				auto_advance_message()
			else:
				advance_message()
		elif style == 1:
			if not show_name:
				text_boxes_name.hide()
			if not show_avatar_:
				text_boxes_avatar.hide()
				
			if auto_skip:
				auto_advance_message()
			else:
				advance_message()
		else:
			advance_message()

func _process(delta: float) -> void:
	if style == 0 and not auto_skip and not selecting_choice.condition:
		if Input.is_action_just_pressed("ui_accept"):
			advance_message()
	elif style == 1 and not auto_skip:
		if Input.is_action_just_pressed("ui_accept"):
			advance_message()

func advance_message():
	message_position += 1
	if message_position < messages.size():
		# Getting the dialogue parts
		var dialogue = messages[message_position].split(separator)
		
		# Showing the name and message
		if dialogue[0] == "1":
			if style == 0:
				subtitles_name.modulate = name_color_
				if typing_animation:
					subtitles_message.percent_visible = 0
				if get_node_or_null("localization_manager"):
					subtitles_name.text = get_node("localization_manager").translated_text(name_) + ":"
					subtitles_message.text = get_node("localization_manager").translated_text(dialogue[1])
				else:
					subtitles_name.text = name_ + ":"
					subtitles_message.text = dialogue[1]
			elif style == 1:
				text_boxes_name.modulate = name_color_
				if typing_animation:
					text_boxes_message.percent_visible = 0
				if get_node_or_null("localization_manager"):
					text_boxes_name.text = get_node("localization_manager").translated_text(name_) 
					text_boxes_message.text = get_node("localization_manager").translated_text(dialogue[1])
				else:
					text_boxes_name.text = name_
					text_boxes_message.text = dialogue[1]
				text_boxes_avatar.texture = avatar_
				if swap_speaker:
					move_to_front(text_boxes_content)
					text_boxes_name.set_h_size_flags(0)
					text_boxes_message.set_align(Label.ALIGN_LEFT)
		elif dialogue[0] == "2":
			if style == 0:
				subtitles_name.modulate = name_color__
				if typing_animation:
					subtitles_message.percent_visible = 0
				if get_node_or_null("localization_manager"):
					subtitles_name.text = get_node("localization_manager").translated_text(name__) + ":"
					subtitles_message.text = get_node("localization_manager").translated_text(dialogue[1])
				else:
					subtitles_name.text = name__ + ":"
					subtitles_message.text = dialogue[1]
					type_message(int(dialogue[2]))
			elif style == 1:
				text_boxes_name.modulate = name_color__
				if typing_animation:
					text_boxes_message.percent_visible = 0
				if get_node_or_null("localization_manager"):
					text_boxes_name.text = get_node("localization_manager").translated_text(name__)
					text_boxes_message.text = get_node("localization_manager").translated_text(dialogue[1])
				else:
					text_boxes_name.text = name__
					text_boxes_message.text = dialogue[1]
				text_boxes_avatar.texture = avatar__
				if swap_speaker:
					move_to_front(text_boxes_avatar)
					text_boxes_name.set_h_size_flags(8)
					text_boxes_message.set_align(Label.ALIGN_RIGHT)
				
		# Apply the animations
		if typing_animation:
			type_message(int(dialogue[2]))
				
		# Showing the choices
		if dialogue.size() >= 4 and style == 0:
			selecting_choice.condition = true
			click_detector.hide()
			selecting_choice.dialogue = dialogue
			
			if not auto_skip:
				if typing_animation:
					timer.wait_time = message_timeouts[message_position]*0.6
					timer.start()
				else:
					add_choices(dialogue)
				
		# Send a notification
		emit_signal("showed_message", dialogue[1], int(dialogue[0]))
	else:
		queue_free()

func auto_advance_message():
	advance_message()
	if message_position < messages.size():
		timer.wait_time = message_timeouts[message_position]
		timer.start()

func continue_to(chosen_dialogue: String):
	refresh()
	start(chosen_dialogue)

func refresh():
	selecting_choice.dialogue.clear()
	tween_out_subtitles_bar()
	remove_choices()
	messages = []
	message_position = -1
	message_timeouts = []
	selecting_choice = {
	"condition": false,
	"dialogue": {}
	}
	tween = null
	set_physics_process(false)
	$VBoxContainer.hide()
	$TextBoxes.hide()

func _on_click_detector_pressed() -> void:
	if style == 0 and not auto_skip and not selecting_choice.condition:
		advance_message()
	elif style == 1 and not auto_skip:
		advance_message()

func move_to_front(node):
	var parent = node.get_parent()
	parent.move_child(node, parent.get_child_count() - 1)

# Subtitles
func _on_Timer_timeout():
	if auto_skip:
		if style == 0:
			if selecting_choice.condition:
				selecting_choice.condition = false
				click_detector.hide()
				timer.wait_time = int(selecting_choice.dialogue[3])
				
				tween_in_subtitles_bar()
				add_choices(selecting_choice.dialogue)
				timer.start()
			else:
				if not selecting_choice.dialogue.empty():
					var temp = selecting_choice.dialogue[1]
					refresh()
					emit_signal("made_choice", "", temp)
				else:
					auto_advance_message()
		elif style == 1:
			auto_advance_message()
	else:
		if style == 0:
			add_choices(selecting_choice.dialogue)

func selected_choice(choice: String) -> void:
	var temp = selecting_choice.dialogue[1]
	refresh()
	emit_signal("made_choice", choice, temp)

func add_choices(dialogue: Array):
	# Add choices
	var choices_amount = 0
	for pos in dialogue.size():
		if pos >= 4:
			choices_amount += 1
			var button = load("res://addons/dialogue/scenes/button.tscn").instance()
			if get_node_or_null("localization_manager"):
				button.text = get_node("localization_manager").translated_text(dialogue[pos])
			else:
				button.text = dialogue[pos]
			button.choice = dialogue[pos]
			button.connect("selected_choice", self, "selected_choice")
			choices_grid.add_child(button)
	choices_grid.columns = choices_amount

func remove_choices():
	for child in choices_grid.get_children():
		child.queue_free()

func tween_in_subtitles_bar():
	subtitles_bar.value = 100
	subtitles_bar.show()
	tween = create_tween()
	tween.tween_property(subtitles_bar, "value", 0, int(selecting_choice.dialogue[3]) - int(selecting_choice.dialogue[3])*0.1).set_trans(Tween.TRANS_SINE)

func tween_out_subtitles_bar():
	subtitles_bar.hide()

# Subtitles and TextBoxes
func type_message(show_time: int):
	if tween != null:
		tween.kill()
	tween = create_tween()
	if style == 0:
		tween.tween_property(subtitles_message, "percent_visible", 1, show_time*0.6)
	elif style == 1:
		tween.tween_property(text_boxes_message, "percent_visible", 1, show_time*0.6)
