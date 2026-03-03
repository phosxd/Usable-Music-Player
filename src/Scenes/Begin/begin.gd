extends Node


func _ready() -> void:
	get_tree().change_scene_to_packed.call_deferred(SessionManager.get_layout_theme_scene('main'))
