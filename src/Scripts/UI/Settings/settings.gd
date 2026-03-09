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
const credits_popup := preload('res://Scenes/Credits/credits.tscn')
@onready var info_text_template:String = %Info.text


func _ready() -> void:
	@warning_ignore('integer_division')
	%Info.text = info_text_template % [
		LibraryManager.get_cache_size()/1000/1000,
		LibraryManager.database.get('timestamp', 'Never'),
		LibraryManager.get_library_size()/1000/1000,
		LibraryManager.database.tracks.size(),
	]
	%'Library Path'.text = SessionManager.library_location
	%'Dynamic Accents'.set_pressed_no_signal(SessionManager.dynamic_accents)
	%'Visualizer Mode'.selected = SessionManager.visualizer_mode
	%'Layout Theme'.selected = SessionManager.layout_theme
	%'Landing Page'.selected = landing_page_options.find(SessionManager.landing_page)
	%'Fetch Lyrics'.set_pressed_no_signal(SessionManager.fetch_lyrics)
	%'Fetch Artist Cover'.set_pressed_no_signal(SessionManager.fetch_artist_cover)
	%'Image Detail'.set_value_no_signal(SessionManager.image_detail)
	%'Track Finished Notif'.set_pressed_no_signal(SessionManager.send_track_finished_notif)
	%'Library Scan Finished Notif'.set_pressed_no_signal(SessionManager.send_library_scan_finished_notif)


func _on_select_library_pressed() -> void:
	if LibraryManager.currently_updating: return
	@warning_ignore('shadowed_variable_base_class')
	var popup:FileDialog = dir_open_popup.instantiate()
	popup.dir_selected.connect(func(path:String) -> void:
		_on_library_path_text_submitted(path)
	)
	self.add_child(popup)
	popup.show()


func _on_library_path_text_submitted(new_text:String) -> void:
	if LibraryManager.currently_updating: return
	LibraryManager.load_library(new_text, func()->void:pass)


func _on_rescan_library_pressed() -> void:
	if LibraryManager.currently_updating: return
	_on_library_path_text_submitted(%'Library Path'.text)


func _on_user_data_pressed() -> void:
	OS.shell_show_in_file_manager(OS.get_user_data_dir())


func _on_source_code_pressed() -> void:
	OS.shell_open(AppInfo.source_code)


func _on_report_issue_pressed() -> void:
	OS.shell_open(AppInfo.issues_page)


func _on_credits_pressed() -> void:
	var popup = credits_popup.instantiate()
	self.add_child(popup)


func _on_dynamic_accents_toggled(toggled_on:bool) -> void:
	SessionManager.dynamic_accents = toggled_on


func _on_visualizer_mode_item_selected(index:int) -> void:
	SessionManager.visualizer_mode = index as SessionManager.VisualizerMode


func _on_layout_theme_item_selected(index:int) -> void:
	match index:
		0: SessionManager.layout_theme = SessionManager.LayoutTheme.Normal
		1: SessionManager.layout_theme = SessionManager.LayoutTheme.Rounded


func _on_landing_page_item_selected(index:int) -> void:
	SessionManager.landing_page = landing_page_options[index]


func _on_fetch_lyrics_toggled(toggled_on:bool) -> void:
	SessionManager.fetch_lyrics = toggled_on


func _on_fetch_artist_cover_toggled(toggled_on:bool) -> void:
	SessionManager.fetch_artist_cover = toggled_on


func _on_fetch_album_cover_toggled(_toggled_on:bool) -> void:
	pass


func _on_play_pause_key_pressed() -> void:
	pass # Replace with function body.


func _on_skip_backward_key_pressed() -> void:
	pass # Replace with function body.


func _on_skip_forward_key_pressed() -> void:
	pass # Replace with function body.


func _on_page_back_key_pressed() -> void:
	pass # Replace with function body.


func _on_image_detail_value_changed(value:float) -> void:
	SessionManager.image_detail = int(value) as SessionManager.ImageDetail


func _on_scan_for_changes_pressed() -> void:
	LibraryManager.scan_for_changes()


func _on_track_finished_notif_toggled(toggled_on:bool) -> void:
	SessionManager.send_track_finished_notif = toggled_on


func _on_library_scan_finished_notif_toggled(toggled_on:bool) -> void:
	SessionManager.send_library_scan_finished_notif = toggled_on
