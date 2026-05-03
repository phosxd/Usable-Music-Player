extends Timer


func start_animation(targets:Array[float]) -> void:
	var tween:Tween = self.create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_QUART) # Give smoothing effect.
	tween.tween_property(%Player/%Panel, 'position:y', targets[0], 0.6)
	tween.tween_property(%Player/%'Bar Visualizer', 'position_offset:y', targets[1], 0.6)
	tween.play()


func _process(_delta:float) -> void:
	if not %Player/'Bar Visualizer'.get_global_rect().has_point(get_viewport().get_mouse_position()): return

	# If hovering over player while hidden, play animation to show it.
	if self.time_left == 0:
		start_animation([0,0])

	# Reset timer when hovering over player.
	%'Hide Player Timer'.stop()
	%'Hide Player Timer'.start()


func _on_timeout() -> void:
	start_animation([%Player/%Panel.size.y, %Player/%'Bar Visualizer'.size.y])
