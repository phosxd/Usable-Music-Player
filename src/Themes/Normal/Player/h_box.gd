extends HBoxContainer


func _process(_delta:float) -> void:
	%'Track Name'.clip_text = false
	var free_pixels = get_parent_area_size()-get_minimum_size()
	if free_pixels.x > 50:
		%'Title Fade'.hide()
		%'Track Name'.clip_text = false
		#%'Track Name'.text_overrun_behavior = TextServer.TextOverrunFlag.OVERRUN_NO_TRIM
		%'Track Name'.size_flags_horizontal = SIZE_FILL
	else:
		%'Title Fade'.show()
		%'Track Name'.clip_text = true
		#%'Track Name'.text_overrun_behavior = TextServer.TextOverrunFlag.OVERRUN_ENFORCE_ELLIPSIS
		%'Track Name'.size_flags_horizontal = SIZE_EXPAND_FILL
