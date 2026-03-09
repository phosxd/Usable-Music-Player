extends HBoxContainer


func _process(delta:float) -> void:
	if visible:
		$'Icon Contrainer/Icon'.rotation -= delta*2
