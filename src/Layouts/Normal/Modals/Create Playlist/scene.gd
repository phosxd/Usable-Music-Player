extends PanelContainer

signal confirmed(data:Dictionary)
signal denied


func _on_yes_pressed() -> void:
	confirmed.emit({
		'name': %Name.text,
	})
	queue_free()


func _on_no_pressed() -> void:
	denied.emit()
	queue_free()
