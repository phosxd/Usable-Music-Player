extends Control

const settings_popup := preload('res://Scenes/Settings/settings.tscn')


func _on_audio_finished() -> void:
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	self.add_child(settings_popup.instantiate())
