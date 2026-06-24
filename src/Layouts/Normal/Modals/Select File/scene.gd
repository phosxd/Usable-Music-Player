extends Node

signal confirmed(data:Dictionary)
signal denied


func _on_popup_file_selected(path:String) -> void:
	confirmed.emit({
		'path': path,
	})
	queue_free()


func _on_popup_canceled() -> void:
	denied.emit()
	queue_free()
