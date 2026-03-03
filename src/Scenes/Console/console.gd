extends Window


func _ready() -> void:
	%Label.text = '\n'.join(MiniLog.logs)
	MiniLog.signals.log_added.append(_on_log_added)


func _on_log_added(text:String='') -> void:
	%Label.append_text('\n'+text)


func _on_command_text_submitted(_new_text:String) -> void:
	%Command.text = ''


func _on_close_requested() -> void:
	self.queue_free()
