extends Control

signal scan_requested
signal update_requested(data:Array)
signal move_requested(up:bool)
signal remove_requested


func init(library:DBLibrary) -> void:
	%Path.text = library.path


func _on_update_pressed() -> void:
	%Update.disabled = true
	update_requested.emit([%Path.text])


func _on_path_text_changed(_new_text:String) -> void:
	%Update.disabled = false


func _on_move_up_pressed() -> void:
	move_requested.emit(true)


func _on_move_down_pressed() -> void:
	move_requested.emit(false)


func _on_remove_pressed() -> void:
	remove_requested.emit()


func _on_scan_pressed() -> void:
	scan_requested.emit()
