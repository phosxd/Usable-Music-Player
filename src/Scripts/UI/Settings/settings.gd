extends Control

var tab_config:Dictionary[String,Variant] = {
	'sort_mode_button': {
		'enabled': false,
	},
	'ascend_mode_button': {
		'enabled': false,
	},
	'search': {
		'enabled': false,
	},
}
const landing_page_options:Array[String] = [
	'',
	'artists',
	'albums',
	'tracks',
	'genres',
]
const dir_open_popup := preload('res://Scenes/Dir Open/dir_open.tscn')


func _ready() -> void:
	%'Auto Scan Interval'.set_value_no_signal(SessionManager.auto_scan_interval)
	# ---
	@warning_ignore('integer_division')
	%'Dynamic Accents'.set_pressed_no_signal(SessionManager.dynamic_accents)
	%'Custom Accent Toggle'.set_pressed_no_signal(SessionManager.custom_accent_enabled)
	%'Custom Accent'.color = SessionManager.custom_accent
	%'Visualizer Mode'.selected = SessionManager.visualizer_mode
	for item:Dictionary in ThemeManager.registered_themes:
		%'Theme'.add_item(item.get('name',''))
	%'Theme'.selected = ThemeManager.get_theme_index(SessionManager.theme)
	for item:Dictionary in ThemeManager.modes:
		%'Theme Mode'.add_item(item.get('@mode_name',''))
	%'Theme Mode'.selected = ThemeManager.mode
	%'Landing Page'.selected = landing_page_options.find(SessionManager.landing_page)
	# ---
	%'Grid Item Size'.set_value_no_signal(SessionManager.grid_item_size)
	%'Panel Tint'.color = SessionManager.panel_tint
	%'Button Tint'.color = SessionManager.button_tint
	%'Visualizer Bar Count'.set_value_no_signal(SessionManager.visualizer_bar_count)
	%'Visualizer Bar Smoothing'.set_value_no_signal(SessionManager.visualizer_bar_smoothing)
	%'Visualizer Bar Count Slider'.set_value_no_signal(SessionManager.visualizer_bar_count)
	%'Visualizer Bar Smoothing Slider'.set_value_no_signal(SessionManager.visualizer_bar_smoothing)
	# ---
	%'Fetch Lyrics'.set_pressed_no_signal(SessionManager.fetch_lyrics)
	%'Fetch Artist Cover'.set_pressed_no_signal(SessionManager.fetch_artist_cover)
	%'Queue Size Limit'.set_value_no_signal(SessionManager.queue_size_limit)
	var image_detail = SessionManager.image_detail_values.find_key(SessionManager.image_detail)
	if image_detail == null: image_detail = 0
	%'Image Detail'.set_value_no_signal(image_detail)
	%'Track Finished Notif'.set_pressed_no_signal(SessionManager.send_track_finished_notif)
	%'Library Scan Finished Notif'.set_pressed_no_signal(SessionManager.send_library_scan_finished_notif)
	# ---
	%'Replay Gain'.selected = SessionManager.replay_gain_mode


func _on_user_data_pressed() -> void:
	OS.shell_show_in_file_manager(OS.get_user_data_dir())


func _on_source_code_pressed() -> void:
	OS.shell_open(AppInfo.source_code)


func _on_report_issue_pressed() -> void:
	OS.shell_open(AppInfo.issues_page)


func _on_dynamic_accents_toggled(toggled_on:bool) -> void:
	SessionManager.dynamic_accents = toggled_on


func _on_visualizer_mode_item_selected(index:int) -> void:
	SessionManager.visualizer_mode = index as SessionManager.VisualizerMode


func _on_theme_item_selected(index:int) -> void:
	SessionManager.theme = ThemeManager.registered_themes[index].get('id','')


func _on_theme_mode_item_selected(index:int) -> void:
	SessionManager.theme_mode = index


func _on_landing_page_item_selected(index:int) -> void:
	SessionManager.landing_page = landing_page_options[index]


func _on_fetch_lyrics_toggled(toggled_on:bool) -> void:
	SessionManager.fetch_lyrics = toggled_on


func _on_fetch_artist_cover_toggled(toggled_on:bool) -> void:
	SessionManager.fetch_artist_cover = toggled_on


func _on_fetch_album_cover_toggled(_toggled_on:bool) -> void:
	pass


func _on_play_pause_key_pressed() -> void:
	pass


func _on_skip_backward_key_pressed() -> void:
	pass


func _on_skip_forward_key_pressed() -> void:
	pass


func _on_page_back_key_pressed() -> void:
	pass


func _on_image_detail_value_changed(value:float) -> void:
	SessionManager.image_detail = SessionManager.image_detail_values[int(value)]


func _on_track_finished_notif_toggled(toggled_on:bool) -> void:
	SessionManager.send_track_finished_notif = toggled_on


func _on_library_scan_finished_notif_toggled(toggled_on:bool) -> void:
	SessionManager.send_library_scan_finished_notif = toggled_on


func _on_ui_scale_value_changed(_value:float) -> void:
	pass


func _on_label_meta_clicked(meta:Variant) -> void:
	OS.shell_open(meta)


func _on_queue_size_limit_value_changed(value:float) -> void:
	SessionManager.queue_size_limit = int(value)


func _on_custom_accent_toggle_toggled(toggled_on:bool) -> void:
	SessionManager.custom_accent_enabled = toggled_on


func _on_custom_accent_popup_closed() -> void:
	SessionManager.custom_accent = %'Custom Accent'.color


func _on_open_themes_folder_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path('user://THEMES/'))


func _on_grid_item_size_value_changed(value:float) -> void:
	SessionManager.grid_item_size = value


func _on_grid_item_size_small_pressed() -> void:
	%'Grid Item Size'.value = 125


func _on_grid_item_size_normal_pressed() -> void:
	%'Grid Item Size'.value = 175


func _on_grid_item_size_large_pressed() -> void:
	%'Grid Item Size'.value = 230


func _on_panel_tint_popup_closed() -> void:
	SessionManager.panel_tint = %'Panel Tint'.color


func _on_panel_tint_preset_color_pressed(color:Color) -> void:
	%'Panel Tint'.color = color
	_on_panel_tint_popup_closed()


func _on_button_tint_popup_closed() -> void:
	SessionManager.button_tint = %'Button Tint'.color


func _on_button_tint_preset_color_pressed(color:Color) -> void:
	%'Button Tint'.color = color
	_on_button_tint_popup_closed()


func _on_visualizer_bar_count_value_changed(value:float) -> void:
	SessionManager.visualizer_bar_count = int(value)
	%'Visualizer Bar Count'.set_value_no_signal(value)
	%'Visualizer Bar Count Slider'.set_value_no_signal(value)


func _on_visualizer_bar_smoothing_value_changed(value:float) -> void:
	SessionManager.visualizer_bar_smoothing = value
	%'Visualizer Bar Smoothing'.set_value_no_signal(value)
	%'Visualizer Bar Smoothing Slider'.set_value_no_signal(value)


func _on_replay_gain_preamp_value_changed(value:float) -> void:
	SessionManager.replay_gain_preamp = value


func _on_replay_gain_item_selected(index:int) -> void:
	SessionManager.replay_gain_mode = index as SessionManager.ReplayGainMode


func _on_auto_scan_interval_value_changed(value:float) -> void:
	SessionManager.auto_scan_interval = value
