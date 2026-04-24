extends Control

const general_options_menu_scene:PackedScene = preload('res://Themes/Normal/Main/general_options.tscn')
var general_options_menu: Control


func _ready() -> void:
	pass


func _on_general_options_toggled(toggled_on:bool) -> void:
	if toggled_on:
		general_options_menu = general_options_menu_scene.instantiate()
		get_window().add_child(general_options_menu)
		general_options_menu.position = %'General Options'.global_position+Vector2(0,%'General Options'.size.y)
	else:
		if general_options_menu: general_options_menu.queue_free()
