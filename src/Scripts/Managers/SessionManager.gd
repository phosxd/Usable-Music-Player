## Manage the current session.
extends Node

const minilog_importance := MiniLog.Importance.High

enum VisualizerMode {
	OFF,
	GLOW,
	BAR,
}

enum ImageDetail {
	Low,
	Normal,
	High,
}

const property_data:Array[Array] = [
	# Library / API settings.
	['library_location',[TYPE_STRING]],
	['fetch_lyrics',[TYPE_BOOL]],
	['fetch_artist_cover',[TYPE_BOOL]],
	['fetch_album_cover',[TYPE_BOOL]],
	# Performance settings.
	['image_detail',[TYPE_INT]],
	# Shortcut settings.
	#['play_pause_key',[TYPE_INT]],
	# Notification settings.
	['send_track_finished_notif',[TYPE_BOOL]],
	['send_library_scan_finished_notif',[TYPE_BOOL]],
	# Tab data.
	['last_tab',[TYPE_STRING]],
	['artists_tab_scroll_value',[TYPE_FLOAT]],
	['albums_tab_scroll_value',[TYPE_FLOAT]],
	['tracks_tab_scroll_value',[TYPE_FLOAT]],
	# Sort data.
	['artist_sort_mode',[TYPE_INT]],
	['artist_ascend_mode',[TYPE_BOOL]],
	['album_sort_mode',[TYPE_INT]],
	['album_ascend_mode',[TYPE_BOOL]],
	['track_sort_mode',[TYPE_INT]],
	['track_ascend_mode',[TYPE_BOOL]],
	# UI settings.
	['layout_theme',[TYPE_STRING]],
	['visualizer_mode',[TYPE_INT]],
	['dynamic_accents',[TYPE_BOOL]],
	['landing_page',[TYPE_STRING]],
]

## Emitted when the session has been loaded.
signal session_loaded
signal value_changed(property_name:String)
## Path to the session file.
const session_file_path:String = 'user://session.json'

var main_scene: Node

## The default window size.
var default_window_size: Vector2i:
	set(value):
		default_window_size = value
		value_changed.emit('default_window_size')

## The current window size.
var current_window_size: Vector2i:
	set(value):
		current_window_size = value
		value_changed.emit('current_window_size')

var library_location:String = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)
var fetch_lyrics:bool = true
var fetch_artist_cover:bool = false
var fetch_album_cover:bool = false

var send_track_finished_notif:bool = true
var send_library_scan_finished_notif:bool = true

## Image detail for album & artist covers.
## Resets cached album cover images when set.
var image_detail := ImageDetail.Normal:
	set(value):
		image_detail = value
		for album:DBAlbum in LibraryManager.get_albums_sorted():
			album._cover = null
		value_changed.emit('image_detail')

## Global search term.
var search_term:String = '':
	set(value):
		search_term = value
		value_changed.emit('search_term')


#region sorting

## Artists tab sort mode.
var artist_sort_mode := LibraryManager.ArtistSortMode.TITLE:
	set(value):
		artist_sort_mode = value
		value_changed.emit('artist_sort_mode')

## Artists tab ascend mode.
var artist_ascend_mode:bool = true:
	set(value):
		artist_ascend_mode = value
		value_changed.emit('artist_ascend_mode')

## Albums tab sort mode.
var album_sort_mode := LibraryManager.AlbumSortMode.TITLE:
	set(value):
		album_sort_mode = value
		value_changed.emit('album_sort_mode')

## Albums tab ascend mode.
var album_ascend_mode:bool = true:
	set(value):
		album_ascend_mode = value
		value_changed.emit('album_ascend_mode')

## Tracks tab sort mode.
var track_sort_mode := LibraryManager.TrackSortMode.TITLE:
	set(value):
		track_sort_mode = value
		value_changed.emit('track_sort_mode')

## Tracks tab ascend mode.
var track_ascend_mode:bool = true:
	set(value):
		track_ascend_mode = value
		value_changed.emit('track_ascend_mode')

var dynamic_accents:bool = true:
	set(value):
		dynamic_accents = value
		value_changed.emit('dynamic_accents')

var visualizer_mode:VisualizerMode = VisualizerMode.OFF:
	set(value):
		visualizer_mode = value
		value_changed.emit('visualizer_mode')

var landing_page:String = '':
	set(value):
		landing_page = value
		value_changed.emit('landing_page')

var last_tab:String = 'albums':
	set(value):
		last_tab = value
		value_changed.emit('last_tab')

var artists_tab_scroll_value:float = 0
var albums_tab_scroll_value:float = 0
var tracks_tab_scroll_value:float = 0

#endregion


var layout_theme: String:
	set(value):
		layout_theme = value

		# Set main scene.
		var tree:SceneTree = get_tree()
		get_tree().change_scene_to_packed.call_deferred(get_layout_theme_scene('Main/main'))
		main_scene = tree.current_scene

		# Call init script.
		var init = Node.new()
		var init_script_path:String = 'res://Themes/%s/init.gd' % value
		if ResourceLoader.exists(init_script_path):
			init.set_script(load(init_script_path))
			init.call('init')

		# Set theme.
		var theme_path:String = 'res://Themes/%s/theme.tres' % value
		if ResourceLoader.exists(theme_path):
			get_window().theme = load(theme_path)
			MiniLog.info('Set theme to "$~%s~$".' % theme_path, SessionManager)

		value_changed.emit('layout_theme')


var valid_layout_themes:Array[String] = []


func _ready() -> void:
	default_window_size = get_window().size
	current_window_size = default_window_size
	for dir_name:String in DirAccess.get_directories_at('res://Themes'):
		valid_layout_themes.append(dir_name)
	load_session()
	if layout_theme.is_empty(): layout_theme = 'Normal' # Set default layout theme if none set by session file.


## Get the scene at [param scene_name] for the current theme or [param theme_override].
func get_layout_theme_scene(scene_name:String, theme_override:String='', recurse:int=0) -> PackedScene:
	if recurse > 1: return null
	var theme_: String
	if theme_override.is_empty(): theme_ = layout_theme
	else: theme_ = theme_override

	var scene
	var scene_path:String = 'res://Themes/%s/%s.tscn' % [theme_, scene_name]
	if ResourceLoader.exists(scene_path): scene = load(scene_path)
	if not scene: return SessionManager.get_layout_theme_scene(scene_name, 'Normal', recurse+1)
	return scene


## Returns the icon at [param icon_name] for the current theme or [param theme_override].
func get_icon(icon_name:String, theme_override:String='', recurse:int=0) -> Texture2D:
	if recurse > 1: return null
	var theme_: String
	if theme_override.is_empty(): theme_ = layout_theme
	else: theme_ = theme_override

	var icon
	var icon_path:String = 'res://Themes/%s/Assets/Icons/%s.svg' % [theme_, icon_name]
	if ResourceLoader.exists(icon_path): icon = load(icon_path)
	if not icon: return SessionManager.get_icon(icon_name, 'Normal', recurse+1)
	return icon


## Load session from disk.
## May override current playing track in PlayerManager.
func load_session() -> void:
	MiniLog.info('Loading session.', SessionManager)
	var file := FileAccess.open(session_file_path, FileAccess.READ)
	if file == null: return
	var data = JSON.parse_string(file.get_as_text())
	if data == null: return

	for i in property_data:
		var data_entry = data.get(i[0])
		if typeof(data_entry) == TYPE_FLOAT && TYPE_INT in i[1] && TYPE_FLOAT not in i[1]:
			data_entry = int(data_entry)
		if typeof(data_entry) in i[1]:
			set(i[0], data_entry)

	PlayerManager.queue.clear()
	var raw_queue = data.get('queue')
	if raw_queue is Array:
		for path in raw_queue:
			if path is not String: continue
			var track = LibraryManager.get_track(path)
			if track: PlayerManager.add_to_queue(track, false)

	PlayerManager.queue_updated.emit()
	var raw_queue_position = data.get('queue_position')
	if (raw_queue_position is int or raw_queue_position is float) && raw_queue_position != -1:
		PlayerManager.set_current_track(int(raw_queue_position), false)

	var raw_track_progress = data.get('track_progress')
	if raw_track_progress is float:
		PlayerManager.set_track_progress(raw_track_progress)

	var raw_volume = data.get('volume')
	if raw_volume is float:
		PlayerManager.set_volume(raw_volume)

	var raw_auto_queue_start_index = data.get('auto_queue_start_index')
	if (raw_auto_queue_start_index is int or raw_auto_queue_start_index is float) && raw_auto_queue_start_index != -1:
		PlayerManager.auto_queue_start_index = int(raw_auto_queue_start_index)

	session_loaded.emit()
	MiniLog.info('Session loaded.', SessionManager)


## Save the current session to disk.
func save_session() -> void:
	var data = {
		'queue': [],
		'queue_position': PlayerManager.queue_position,
		'auto_queue_start_index': PlayerManager.auto_queue_start_index,
		'track_progress': PlayerManager.track_progress,
		'volume': PlayerManager.get_volume(),
	}

	for i in property_data:
		data.set(i[0], self.get(i[0]))

	for track:DBTrack in PlayerManager.queue:
		data.queue.append(track.path)

	var file := FileAccess.open(session_file_path, FileAccess.WRITE)
	var json = JSON.stringify(data, '\t', true, true)
	file.store_string(json)
	file.close()


func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		current_window_size = get_window().size
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_session()
		get_tree().quit()
