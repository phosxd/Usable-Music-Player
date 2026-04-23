extends Control

signal update_requested(data:Array)
signal move_requested(up:bool)
signal remove_requested


func init(data:Array) -> void:
	if data.size() != 4: return
	%URL.text = data[1]
	%Username.text = data[2]
	%Password.text = data[3]


func _on_update_pressed() -> void:
	%Update.disabled = true
	update_requested.emit([%URL.text, %Username.text, %Password.text])


func _on_changed(_new_text:String) -> void:
	%Update.disabled = false


func _on_move_up_pressed() -> void:
	move_requested.emit(true)


func _on_move_down_pressed() -> void:
	move_requested.emit(false)


func _on_remove_pressed() -> void:
	remove_requested.emit()
