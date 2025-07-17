extends Button

signal selected_choice(choice)

var choice: String

func _on_Button_pressed():
	emit_signal("selected_choice", choice)
