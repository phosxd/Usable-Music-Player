extends Control

const section:String = 'theme'


func _ready() -> void:
	%'Theme Fold'.folded = self.section in SessionManager.folded_sections
	# ---
	for item:Dictionary in ThemeManager.registered_themes:
		%'Theme'.add_item(item.get('name',''))
	%'Theme'.selected = ThemeManager.get_theme_index(SessionManager.theme)
	for item:Dictionary in ThemeManager.modes:
		%'Theme Mode'.add_item(item.get('@mode_name',''))
	%'Theme Mode'.selected = ThemeManager.mode
	# ---
	%'Accent Mode'.selected = SessionManager.accent_mode
	%'Custom Accent'.color = SessionManager.custom_accent
	%'Panel Tint'.color = SessionManager.panel_tint
	%'Button Tint'.color = SessionManager.button_tint
	# ---
	%'Visualizer Mode'.selected = SessionManager.visualizer_mode
	%'Visualizer Bar Count'.set_value_no_signal(SessionManager.visualizer_bar_count)
	%'Visualizer Bar Smoothing'.set_value_no_signal(SessionManager.visualizer_bar_smoothing)
	%'Visualizer Bar Count Slider'.set_value_no_signal(SessionManager.visualizer_bar_count)
	%'Visualizer Bar Smoothing Slider'.set_value_no_signal(SessionManager.visualizer_bar_smoothing)


func _on_theme_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && self.section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(self.section)
	else:
		SessionManager.folded_sections.erase(self.section)


func _on_theme_mode_item_selected(index:int) -> void:
	SessionManager.theme_mode = index


func _on_open_themes_folder_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path('user://THEMES/'))


func _on_accent_mode_item_selected(index:int) -> void:
	SessionManager.accent_mode = index as SessionManager.AccentMode


func _on_custom_accent_color_changed(color:Color) -> void:
	SessionManager.custom_accent = color


func _on_panel_tint_color_changed(color:Color) -> void:
	SessionManager.panel_tint = color
	ThemeManager.apply_changes()


func _on_panel_tint_preset_color_pressed(color:Color) -> void:
	%'Panel Tint'.color = color
	_on_panel_tint_color_changed(color)


func _on_button_tint_color_changed(color:Color) -> void:
	SessionManager.button_tint = color
	ThemeManager.apply_changes()


func _on_button_tint_preset_color_pressed(color:Color) -> void:
	%'Button Tint'.color = color
	_on_button_tint_color_changed(color)


func _on_visualizer_mode_item_selected(index:int) -> void:
	SessionManager.visualizer_mode = index as SessionManager.VisualizerMode


func _on_visualizer_bar_count_value_changed(value:float) -> void:
	SessionManager.visualizer_bar_count = int(value)
	%'Visualizer Bar Count'.set_value_no_signal(value)
	%'Visualizer Bar Count Slider'.set_value_no_signal(value)


func _on_visualizer_bar_smoothing_value_changed(value:float) -> void:
	SessionManager.visualizer_bar_smoothing = value
	%'Visualizer Bar Smoothing'.set_value_no_signal(value)
	%'Visualizer Bar Smoothing Slider'.set_value_no_signal(value)


func _on_theme_apply_changes_pressed() -> void:
	ThemeManager.apply_changes()
