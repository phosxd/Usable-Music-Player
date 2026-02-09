extends Window


func _on_close_requested() -> void:
	self.hide()
	self.queue_free()


func _on_close_pressed() -> void:
	_on_close_requested()


func _on_select_library_pressed() -> void:
	pass


func _on_library_path_text_changed(new_text:String) -> void:
	pass
