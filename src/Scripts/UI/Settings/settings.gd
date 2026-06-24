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


func _ready() -> void:
	%'Auto Scan Interval'.set_value_no_signal(SessionManager.get_var('auto_scan_interval'))
	# ---
	%'Grid Item Size'.set_value_no_signal(SessionManager.get_var('grid_item_size'))
	# ---
	%'Fetch Lyrics'.set_pressed_no_signal(SessionManager.get_var('fetch_lyrics'))
	%'Fetch Artist Cover'.set_pressed_no_signal(SessionManager.get_var('fetch_artist_cover'))
	%'Queue Size Limit'.set_value_no_signal(SessionManager.get_var('queue_size_limit'))
	%'Track Finished Notif'.set_pressed_no_signal(SessionManager.get_var('send_track_finished_notif'))
	%'Library Scan Finished Notif'.set_pressed_no_signal(SessionManager.get_var('send_library_scan_finished_notif'))


func _on_user_data_pressed() -> void:
	OS.shell_show_in_file_manager(OS.get_user_data_dir())


func _on_source_code_pressed() -> void:
	OS.shell_open(AppInfo.source_code)


func _on_report_issue_pressed() -> void:
	OS.shell_open(AppInfo.issues_page)


func _on_dynamic_accents_toggled(toggled_on:bool) -> void:
	SessionManager.set_var('dynamic_accents', toggled_on)


func _on_visualizer_mode_item_selected(index:int) -> void:
	SessionManager.set_var('visualizer_mode', index)


func _on_theme_item_selected(index:int) -> void:
	SessionManager.set_var('theme', ThemeManager.registered_themes[index].get('id',''))


func _on_theme_mode_item_selected(index:int) -> void:
	SessionManager.set_var('theme_mode', index)


func _on_fetch_lyrics_toggled(toggled_on:bool) -> void:
	SessionManager.set_var('fetch_lyrics', toggled_on)


func _on_fetch_artist_cover_toggled(toggled_on:bool) -> void:
	SessionManager.set_var('fetch_artist_cover', toggled_on)


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


func _on_track_finished_notif_toggled(toggled_on:bool) -> void:
	SessionManager.set_var('send_track_finished_notif', toggled_on)


func _on_library_scan_finished_notif_toggled(toggled_on:bool) -> void:
	SessionManager.set_var('send_library_scan_finished_notif', toggled_on)


func _on_label_meta_clicked(meta:Variant) -> void:
	OS.shell_open(meta)


func _on_queue_size_limit_value_changed(value:float) -> void:
	SessionManager.set_var('queue_size_limit', int(value))


func _on_grid_item_size_value_changed(value:float) -> void:
	SessionManager.set_var('grid_item_size', value)


func _on_grid_item_size_small_pressed() -> void:
	%'Grid Item Size'.value = 125


func _on_grid_item_size_normal_pressed() -> void:
	%'Grid Item Size'.value = 175


func _on_grid_item_size_large_pressed() -> void:
	%'Grid Item Size'.value = 230


func _on_auto_scan_interval_value_changed(value:float) -> void:
	SessionManager.set_var('auto_scan_interval', value)
