extends Control

var is_dragging:bool = false


func _on_drag_button_button_down() -> void:
	is_dragging = true
	var list = self.get_parent()
	if list is not ReorderableContainer: return
	list._focus_child = self
	list._is_press = true


func _on_drag_button_button_up() -> void:
	is_dragging = false
	var list = self.get_parent()
	if list is not ReorderableContainer: return
	list._is_press = false
