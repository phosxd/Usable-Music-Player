class_name _ContextMenuPopup extends PopupMenu


func _process(_delta:float) -> void:
	if not visible: return
	if Input.is_action_just_pressed('right_click'):
		hide()
