extends Node

func _ready() -> void:
	var margin:MarginContainer = SessionManager.main_scene.get_node('%Scene Margin')
	margin.add_theme_constant_override('margin_left', 0)
	margin.add_theme_constant_override('margin_top', 0)
	margin.add_theme_constant_override('margin_right', 0)
	margin.add_theme_constant_override('margin_bottom', 0)
	var player:PanelContainer = SessionManager.main_scene.get_node('%Player/Panel')
	var player_style = player.get_theme_stylebox('panel')
	player_style.corner_radius_top_right = 0
	player_style.corner_radius_bottom_right = 0
	player.add_theme_stylebox_override('panel', player_style)
	var player_bar:MarginContainer = SessionManager.main_scene.get_node('%Player Bar')
	player_bar.add_theme_constant_override('margin_right', 0)


func _exit_tree() -> void:
	var margin:MarginContainer = SessionManager.main_scene.get_node('%Scene Margin')
	margin.add_theme_constant_override('margin_left', 10)
	margin.add_theme_constant_override('margin_top', 10)
	margin.add_theme_constant_override('margin_right', 0)
	margin.add_theme_constant_override('margin_bottom', 10)
	var player:PanelContainer = SessionManager.main_scene.get_node('%Player/Panel')
	var player_style = player.get_theme_stylebox('panel')
	player_style.corner_radius_top_right = 16
	player_style.corner_radius_bottom_right = 16
	player.add_theme_stylebox_override('panel', player_style)
	var player_bar:MarginContainer = SessionManager.main_scene.get_node('%Player Bar')
	player_bar.add_theme_constant_override('margin_right', 10)
