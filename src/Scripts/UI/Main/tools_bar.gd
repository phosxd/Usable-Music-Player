extends Control

@onready var visibility_menu_scene:PackedScene = SessionManager.get_scene('Main/visiblity_menu')
var visibility_menu: Control


func _on_visibility_toggled(toggled_on:bool) -> void:
	if toggled_on:
		visibility_menu = visibility_menu_scene.instantiate()
		get_window().add_child(visibility_menu)
		visibility_menu.position = %Visibility.global_position+Vector2(0,%Visibility.size.y)
	else:
		if visibility_menu: visibility_menu.queue_free()
