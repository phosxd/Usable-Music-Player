@tool
extends Button

signal color_pressed(color:Color)

@export var color := Color.WHITE:
	set(value):
		color = value
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(280)
		$Margin/Center/Panel.add_theme_stylebox_override('panel', style)


func _on_pressed() -> void:
	color_pressed.emit(color)
