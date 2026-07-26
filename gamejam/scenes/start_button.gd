extends TextureButton
@onready var button_sound: AudioStreamPlayer = $ButtonSound



func _pressed() -> void:
	button_sound.play()
	await button_sound.finished
	get_tree().change_scene_to_file("res://scenes/IntroStory.tscn")
