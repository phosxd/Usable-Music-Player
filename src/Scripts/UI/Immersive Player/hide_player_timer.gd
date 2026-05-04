extends Timer

@export var wait_time_2: float

var tweens: Array[Tween]


func start_animation(targets:Array[float], duration:float) -> void:
	# Kill any previous animations.
	for tween:Tween in tweens:
		tween.kill()

	# Start animation.
	var tween:Tween = self.create_tween()
	tweens.append(tween)
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_QUART) # Give smoothing effect.
	tween.tween_property(%Player/%Panel, 'position:y', targets[0], duration)
	tween.tween_property(%Player/%'Bar Visualizer', 'position_offset:y', targets[1], duration)
	tween.play()


func _process(_delta:float) -> void:
	if not %Player/'Bar Visualizer'.get_global_rect().has_point(get_viewport().get_mouse_position()): return

	# If hovering over player while hidden, play animation to show it.
	if self.time_left == 0:
		start_animation([0,0], 0.5)

	# Reset timer when hovering over player.
	%'Hide Player Timer'.stop()
	%'Hide Player Timer'.start()


func _on_timeout() -> void:
	start_animation([%Player/%Panel.size.y, %Player/%'Bar Visualizer'.size.y], 0.75)
	self.wait_time = wait_time_2
