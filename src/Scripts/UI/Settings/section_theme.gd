extends Control

const section:String = 'Theme'


func _ready() -> void:
	%'Theme Fold'.folded = section in SessionManager.get_var('folded_sections')
	# ---
	for item:Dictionary in ThemeManager.registered_themes:
		%'Theme'.add_item(item.get('name',''))
	%'Theme'.selected = ThemeManager.get_theme_index(SessionManager.get_var('theme'))
	for item:Dictionary in ThemeManager.modes:
		%'Theme Mode'.add_item(item.get('@mode_name',''))
	%'Theme Mode'.selected = ThemeManager.mode
	# ---
	%'Accent Mode'.selected = SessionManager.get_var('accent_mode')
	%'Custom Accent'.color = SessionManager.get_var('custom_accent')
	%'Panel Tint'.color = SessionManager.get_var('panel_tint')
	%'Button Tint'.color = SessionManager.get_var('button_tint')
	# ---
	%'Visualizer Mode'.selected = SessionManager.get_var('visualizer_mode')
	%'Visualizer Bar Count'.set_value_no_signal(SessionManager.get_var('visualizer_bar_count'))
	%'Visualizer Bar Smoothing'.set_value_no_signal(SessionManager.get_var('visualizer_bar_smoothing'))
	%'Visualizer Bar Count Slider'.set_value_no_signal(SessionManager.get_var('visualizer_bar_count'))
	%'Visualizer Bar Smoothing Slider'.set_value_no_signal(SessionManager.get_var('visualizer_bar_smoothing'))


func _on_theme_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && section not in SessionManager.get_var('folded_sections'):
		SessionManager.get_var('folded_sections').append(section)
	else:
		SessionManager.get_var('folded_sections').erase(section)


func _on_theme_mode_item_selected(index:int) -> void:
	SessionManager.set_var('theme_mode', index)


func _on_open_themes_folder_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path('user://THEMES/'))


func _on_accent_mode_item_selected(index:int) -> void:
	SessionManager.set_var('accent_mode', index)


func _on_custom_accent_color_changed(color:Color) -> void:
	SessionManager.set_var('custom_accent', color)


func _on_panel_tint_color_changed(color:Color) -> void:
	SessionManager.set_var('panel_tint', color)
	ThemeManager.apply_changes()


func _on_panel_tint_preset_color_pressed(color:Color) -> void:
	%'Panel Tint'.color = color
	_on_panel_tint_color_changed(color)


func _on_button_tint_color_changed(color:Color) -> void:
	SessionManager.set_var('button_tint', color)
	ThemeManager.apply_changes()


func _on_button_tint_preset_color_pressed(color:Color) -> void:
	%'Button Tint'.color = color
	_on_button_tint_color_changed(color)


func _on_visualizer_mode_item_selected(index:int) -> void:
	SessionManager.set_var('visualizer_mode', index)


func _on_visualizer_bar_count_value_changed(value:float) -> void:
	SessionManager.set_var('visualizer_bar_count', int(value))
	%'Visualizer Bar Count'.set_value_no_signal(value)
	%'Visualizer Bar Count Slider'.set_value_no_signal(value)


func _on_visualizer_bar_smoothing_value_changed(value:float) -> void:
	SessionManager.set_var('visualizer_bar_smoothing', value)
	%'Visualizer Bar Smoothing'.set_value_no_signal(value)
	%'Visualizer Bar Smoothing Slider'.set_value_no_signal(value)


func _on_theme_apply_changes_pressed() -> void:
	ThemeManager.apply_changes()
