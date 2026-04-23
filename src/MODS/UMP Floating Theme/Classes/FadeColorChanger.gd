extends Node

@export var fade_nodes:Array[TextureRect] = []


func _ready() -> void:
	var parent:PanelContainer = get_parent()
	var color = parent.get_theme_stylebox('panel').bg_color
	for node:TextureRect in fade_nodes:
		node.texture.gradient.set_color(0, color)
