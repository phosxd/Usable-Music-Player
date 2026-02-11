extends AcceptDialog


func _on_close_requested() -> void:
	self.hide()
	self.queue_free()
