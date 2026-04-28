class_name FileDialogCustom extends FileDialog


func _on_close_requested() -> void:
	self.hide()
	self.queue_free()


func _on_canceled() -> void:
	_on_close_requested()


func _on_file_selected(_path:String) -> void:
	_on_close_requested()


func _on_dir_selected(_dir:String) -> void:
	_on_close_requested()
