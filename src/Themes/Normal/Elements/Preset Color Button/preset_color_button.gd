@tool
extends Button

signal color_pressed(color:Color)

@export var color := Color.WHITE:
	set(value):
		color = value
		var style := StyleBoxFlat.new()
		var bg_color:Color = color
		bg_color.a = 0.5 if bg_color.a > 0 else 0.0
		style.bg_color = bg_color
		style.set_corner_radius_all(280)
		$Margin/Center/Panel.add_theme_stylebox_override('panel', style)


func _on_pressed() -> void:
	color_pressed.emit(color)
