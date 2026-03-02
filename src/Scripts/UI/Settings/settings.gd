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
const info_popup := preload('res://Scenes/Info Popup/info_popup.tscn')
const credits_popup := preload('res://Scenes/Credits/credits.tscn')
@onready var info_text_template:String = %Info.text
@onready var settings:Array[Node] = [%Info, %'Library Path', %'Dynamic Accents', %'Visualizer Mode', %'Layout Theme', %'Landing Page', %'Fetch Lyrics', %'Fetch Artist Cover']


func _ready() -> void:
	update(settings)


func update(nodes:Array[Node]) -> void:
	@warning_ignore('integer_division')
	nodes[0].text = String(info_text_template) % [
		LibraryManager.get_cache_size()/1000/1000,
		LibraryManager.database.get('timestamp', 'Never'),
		LibraryManager.get_library_size()/1000/1000,
		LibraryManager.database.track_count,
	]
	nodes[1].text = SessionManager.library_location
	nodes[2].button_pressed = SessionManager.dynamic_accents
	nodes[3].selected = SessionManager.visualizer_mode
	nodes[4].selected = SessionManager.layout_theme
	nodes[5].selected = landing_page_options.find(SessionManager.landing_page)
	nodes[6].button_pressed = SessionManager.fetch_lyrics
	nodes[7].button_pressed = SessionManager.fetch_artist_cover


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
	@warning_ignore('shadowed_variable_base_class')
	var popup:AcceptDialog = info_popup.instantiate()
	popup.get_ok_button().hide()
	popup.dialog_text = 'Running a full rescan/reset of the database & cache. This may take some time.\n\nYou can browse & play songs during indexing however you may need to restart the app after indexing to see the full library.'
	self.add_child(popup)
	%'Library Path'.editable = false
	%'Rescan Library'.disabled = true

	LibraryManager.load_library(new_text, (func(scene:Node, library_path:LineEdit, rescan_library:Button, nodes:Array[Node]) -> void:
		if not scene: return
		library_path.editable = true
		library_path.text = new_text
		rescan_library.disabled = false
		update(nodes)
		if popup: popup.queue_free()
	).bind(self, %'Library Path', %'Rescan Library', settings))


func _on_rescan_library_pressed() -> void:
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
