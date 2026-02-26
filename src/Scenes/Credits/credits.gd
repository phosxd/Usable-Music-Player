extends Window


func _on_close_requested() -> void:
	self.hide()
	self.queue_free()


func _on_content_meta_clicked(meta:Variant) -> void:
	OS.shell_open(meta)
