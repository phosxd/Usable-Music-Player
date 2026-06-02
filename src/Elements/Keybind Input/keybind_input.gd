@tool
extends LineEdit

signal keycode_changed(text_keycode:String)

@export var default_keycode: Key:
	set(value):
		default_keycode = value
		reset_key()


func reset_key() -> void:
	self.text = OS.get_keycode_string(default_keycode)
	keycode_changed.emit(self.text)


func _on_gui_input(event:InputEvent) -> void:
	if event is not InputEventKey or event.is_released(): return
	await get_tree().process_frame # Wait a frame to run *after* the text input update.

	event = event as InputEventKey
	self.text = event.as_text_keycode()
	keycode_changed.emit(self.text)


func _on_text_changed(new_text:String) -> void:
	if new_text.is_empty(): reset_key()


func _on_focus_entered() -> void:
	ShortcutManager.ignore_input = true


func _on_focus_exited() -> void:
	ShortcutManager.ignore_input = false
