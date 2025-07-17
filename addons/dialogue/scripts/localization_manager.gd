extends Node

# Functions you can use: forceLanguage("")
# Example: forceLanguage("en_US")

export var separator: String = ";"
export var languages: String = ""
export(Array, String, MULTILINE) var texts = []

onready var os_language = OS.get_locale()
onready var languages_array = languages.split(separator)
var forced_language: String

var texts_arrays = []
var selected_language_position = -1

func _ready() -> void:
	# Split each texts into arrays and add them to the array of texts
	for each in texts:
		texts_arrays.append(each.split(separator))
		
	# Automatically add the language
	if hasExactOSLanguage():
		selected_language_position = getLanguagePosition(os_language)
	elif hasOSLanguage():
		selected_language_position = getLanguagePosition(os_language)
	else:
		selected_language_position = 0

func translated_text(text: String):
	if not texts.empty():
		if hasLanguage(forced_language):
			setLanguage(forced_language)

		# Iterates through each default text
		var default_text_positon = -1
		for default_text in texts_arrays[0]:
			# Save the current position of the default text
			default_text_positon += 1
			# Checks if the root text has that default text
			if default_text == text:
				return texts_arrays[selected_language_position][default_text_positon]
		return text
	return text

func setLanguage(string: String):
	selected_language_position = getLanguagePosition(string)

func forceLanguage(string: String):
	forced_language = string

func getLanguagePosition(string: String):
	for pos in languages_array.size():
		if string == languages_array[pos]:
			return pos 
	return ""

func hasExactOSLanguage():
	if os_language in languages_array:
		return true
	else:
		return false

func hasOSLanguage():
	for language in languages_array:
		if language in os_language:
			return true
	return false

func hasLanguage(string: String):
	if string in languages_array:
		return true
	return false
