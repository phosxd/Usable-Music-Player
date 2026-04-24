extends Control

const dir_open_scene:PackedScene = preload('res://Scenes/Dir Open/dir_open.tscn')

signal scan_requested
signal update_requested(data:Array)
signal move_requested(up:bool)
signal remove_requested


func init(library:DBLibrary) -> void:
	%ID.text = library.id
	%Path.text = library.path


func update() -> void:
	update_requested.emit([%ID.text,%Path.text])


func _on_path_text_changed(_new_text:String) -> void:
	update()


func _on_move_up_pressed() -> void:
	move_requested.emit(true)


func _on_move_down_pressed() -> void:
	move_requested.emit(false)


func _on_remove_pressed() -> void:
	remove_requested.emit()


func _on_scan_pressed() -> void:
	scan_requested.emit()


func _on_load_path_pressed() -> void:
	var popup:FileDialog = dir_open_scene.instantiate()
	popup.show()
	popup.dir_selected.connect(func(dir:String) -> void:
		%Path.text = dir
		_on_path_text_changed(dir)
	)


func _on_id_text_changed(_new_text:String) -> void:
	update()
