extends Node

var global_theme:Theme = ThemeDB.get_project_theme()
const list_1:Array[Array] = [
	['PanelContainer', 0, ['panel']],
	['Button', 4, ['disabled', 'focus', 'hover', 'hover_pressed', 'normal', 'pressed']],
	['AccentButton', 4, ['disabled', 'focus', 'hover', 'hover_pressed', 'normal', 'pressed']],
]


func init() -> void:
	for i in list_1:
		for i2 in i[2]:
			var style:StyleBoxFlat = global_theme.get_stylebox(i2, i[0])
			style.corner_radius_bottom_left = i[1]
			style.corner_radius_bottom_right = i[1]
			style.corner_radius_top_left = i[1]
			style.corner_radius_top_right = i[1]
			global_theme.set_stylebox(i2, i[0], style)
