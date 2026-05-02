extends Timer


func _process(_delta:float) -> void:
	if not %Player/'Bar Visualizer'.get_global_rect().has_point(get_viewport().get_mouse_position()): return
	%Player/%Panel.show()
	%Player/'Bar Visualizer'.align_top = true
	%'Hide Player Timer'.stop()
	%'Hide Player Timer'.start()


func _on_timeout() -> void:
	%Player/%Panel.hide()
	%Player/'Bar Visualizer'.align_top = false
