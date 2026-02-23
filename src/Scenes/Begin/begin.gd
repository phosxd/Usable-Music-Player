extends Node


func _ready() -> void:
	get_tree().change_scene_to_packed(SessionManager.get_layout_theme_scene('main'))
