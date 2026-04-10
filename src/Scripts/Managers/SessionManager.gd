## Manage the current session.
extends Node

const minilog_importance := MiniLog.Importance.High

## Audio visualizer mode.
enum VisualizerMode {
	OFF,
	GLOW,
	BAR,
}

## Image detail levels.
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
	['queue_size_limit',[TYPE_INT]],
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
	['theme',[TYPE_STRING]],
	['visualizer_mode',[TYPE_INT]],
	['dynamic_accents',[TYPE_BOOL]],
	['custom_accent',[TYPE_COLOR]],
	['custom_accent_enabled',[TYPE_BOOL]],
	['landing_page',[TYPE_STRING]],
]

## Emitted when the session has been loaded.
signal session_loaded
signal value_changed(property_name:String)
## Path to the session file.
const session_file_path:String = 'user://session.json'

var main_scene: Node

#region window

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

#endregion

var library_location:String = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)
var fetch_lyrics:bool = true
var fetch_artist_cover:bool = false
var fetch_album_cover:bool = false

var send_track_finished_notif:bool = true
var send_library_scan_finished_notif:bool = true

## The maximum number of items allowed in the queue at once.
var queue_size_limit:int = 150

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

var custom_accent_enabled:bool = false:
	set(value):
		custom_accent_enabled = value
		value_changed.emit('custom_accent_enabled')

var custom_accent := Color(0.9, 0.9, 0.9):
	set(value):
		custom_accent = value
		value_changed.emit('custom_accent')

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

var theme:String = '':
	set(value):
		theme = value
		ThemeManager.set_theme(value)

#region context menues

@onready var context_menus:Dictionary[String,ContextMenu] = {
	'track_card': ContextMenu.new([
		{
			'type': 'button',
			'text': 'Play (clear queue)',
			'icon': SessionManager.get_icon('play'),
		},
		{
			'type': 'button',
			'text': 'Play Next',
			'icon': SessionManager.get_icon('queue_play_next'),
		},
		{
			'type': 'button',
			'text': 'Add To Queue',
			'icon': SessionManager.get_icon('queue_add_to_queue'),
		},
		{
			'type': 'button',
			'text': 'Show Album',
			'icon': SessionManager.get_icon('folder'),
		},
		{
			'type': 'button',
			'text': 'Show In Files',
			'icon': SessionManager.get_icon('folder'),
		},
		{
			'type': 'button',
			'text': 'Rescan',
			'icon': SessionManager.get_icon('modifiers'),
		},
	]),
	'queue_card': ContextMenu.new([
		{
			'type': 'button',
			'text': 'Remove',
			'icon': SessionManager.get_icon('remove'),
		},
		{
			'type': 'button',
			'text': 'Remove This Album',
			'icon': SessionManager.get_icon('remove'),
		},
		{
			'type': 'button',
			'text': 'Remove This Artist',
			'icon': SessionManager.get_icon('remove'),
		},
		{
			'type': 'button',
			'text': 'Show Album',
			'icon': SessionManager.get_icon('folder'),
		},
	]),
}

#endregion


func _ready() -> void:
	default_window_size = get_window().size
	current_window_size = default_window_size

	load_session()
	if theme.is_empty(): theme = 'UMP_DEFAULT' # Set default layout theme if none set by session file.


## Get the scene at [param scene_name] for the current theme or [param theme_override].
func get_layout_theme_scene(scene_name:String, theme_override:String='', recurse:int=0) -> PackedScene:
	if recurse > 1: return null
	var theme_: String
	if theme_override.is_empty(): theme_ = theme
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
	if theme_override.is_empty(): theme_ = theme
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
	var data = A2J.from_json(JSON.parse_string(file.get_as_text()))
	if data == null: return

	for i in property_data:
		var data_entry = data.get(i[0])
		if typeof(data_entry) == TYPE_FLOAT && TYPE_INT in i[1] && TYPE_FLOAT not in i[1]:
			data_entry = int(data_entry)
		if typeof(data_entry) in i[1]:
			set(i[0], data_entry)

	var raw_queue = data.get('queue')
	var tracks:Array[DBTrack] = []
	if raw_queue is Array:
		for path in raw_queue:
			if path is not String: continue
			var track = LibraryManager.get_track(path)
			if track: tracks.append(track)
	PlayerManager.set_queue(tracks)

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
	var json = JSON.stringify(A2J.to_json(data), '\t', true, true)
	file.store_string(json)
	file.close()


func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		current_window_size = get_window().size
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_session()
		get_tree().quit()
