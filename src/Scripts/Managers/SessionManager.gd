## Manage the current session.
extends Node

const minilog_importance := MiniLog.Importance.High

enum LibraryType {
	LocalDirectory,
	NavidromeServer,
}

enum ReplayGainMode {
	None,
	Track,
	Album,
	Auto,
}

enum AccentMode {
	System,
	Dynamic,
	Custom,
}

## Audio visualizer mode.
enum VisualizerMode {
	OFF,
	GLOW,
	BAR,
}

const image_detail_values:Dictionary[int,int] = {
	0: 100,
	1: 300,
	2: 600,
	3: 800,
	4: 1200,
	5: 1800,
}

const sections:Array[Array] = [
	['library', [
		'auto_scan_internal',
	]],
	['theme', [
		'theme',
		'theme_mode',
		'accent_mode',
		'visualizer_mode',
		'visualizer_bar_count',
		'visualizer_bar_smoothing',
		'custom_accent',
		'panel_tint',
		'button_tint',
	]],
	['ui', [
		'landing_page',
		'grid_item_size',
		'queue_size_limit',
		'image_detail',
	]],
	['audio', [
		'replay_gain',
		'replay_gain_preamp',
	]],
	['api', [
		'fetch_lyrics',
		'fetch_artist_cover',
		'fetch_album_cover',
		'send_track_finished_notif',
		'send_library_scan_finished_notif',
	]],
]

const property_data:Array[Array] = [
	# Library settings.
	['library_order',[TYPE_PACKED_STRING_ARRAY]],
	['visible_libraries',[TYPE_PACKED_STRING_ARRAY]],
	['auto_scan_interval',[TYPE_INT,TYPE_FLOAT]],
	# Theme.
	['theme',[TYPE_STRING]],
	['theme_mode',[TYPE_INT]],
	['accent_mode',[TYPE_INT]],
	['visualizer_mode',[TYPE_INT]],
	['visualizer_bar_count',[TYPE_INT]],
	['visualizer_bar_smoothing',[TYPE_FLOAT]],
	['custom_accent',[TYPE_COLOR]],
	['panel_tint',[TYPE_COLOR]],
	['button_tint',[TYPE_COLOR]],
	# UI.
	['landing_page',[TYPE_STRING]],
	['grid_item_size',[TYPE_INT,TYPE_FLOAT]],
	['queue_size_limit',[TYPE_INT]],
	['image_detail',[TYPE_INT]],
	# Audio.
	['replay_gain_mode',[TYPE_INT]],
	['replay_gain_preamp',[TYPE_FLOAT]],
	# API.
	['fetch_lyrics',[TYPE_BOOL]],
	['fetch_artist_cover',[TYPE_BOOL]],
	['fetch_album_cover',[TYPE_BOOL]],
	['send_track_finished_notif',[TYPE_BOOL]],
	['send_library_scan_finished_notif',[TYPE_BOOL]],

	# Tab data.
	['last_tab',[TYPE_STRING]],
	['artists_tab_scroll_value',[TYPE_FLOAT]],
	['albums_tab_scroll_value',[TYPE_FLOAT]],
	['tracks_tab_scroll_value',[TYPE_FLOAT]],
	['right_sidebar_tab',[TYPE_STRING]],
	['tab_content_split',[TYPE_PACKED_INT32_ARRAY]],
	# Sort data.
	['folded_sections',[TYPE_PACKED_STRING_ARRAY]],
	['artist_sort_mode',[TYPE_INT]],
	['artist_ascend_mode',[TYPE_BOOL]],
	['album_sort_mode',[TYPE_INT]],
	['album_ascend_mode',[TYPE_BOOL]],
	['track_sort_mode',[TYPE_INT]],
	['track_ascend_mode',[TYPE_BOOL]],
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

#region library settings

var library_order: PackedStringArray
var visible_libraries: PackedStringArray
## How many minutes to wait before automatically scanning.
var auto_scan_interval:float = 0.5:
	set(value):
		auto_scan_interval = value
		if value == 0: auto_scan_timer.wait_time = 999_999_999_999
		else: auto_scan_timer.wait_time = value*60.0

#endregion

#region theme settings

var theme:String = '':
	set(value):
		theme = value
		ThemeManager.set_theme(value)
		value_changed.emit('theme')

var theme_mode:int = 0:
	set(value):
		theme_mode = value
		ThemeManager.set_theme_mode(value)
		value_changed.emit('theme_mode')

var accent_mode := AccentMode.System:
	set(value):
		accent_mode = value
		value_changed.emit('accent_mode')

var custom_accent := Color(0.9, 0.9, 0.9):
	set(value):
		custom_accent = value
		value_changed.emit('custom_accent')

var visualizer_mode:VisualizerMode = VisualizerMode.OFF:
	set(value):
		visualizer_mode = value
		value_changed.emit('visualizer_mode')

var visualizer_bar_count:int = 125:
	set(value):
		visualizer_bar_count = value
		value_changed.emit('visualizer_bar_count')

var visualizer_bar_smoothing:float = 0.5:
	set(value):
		visualizer_bar_smoothing = value
		value_changed.emit('visualizer_bar_smoothing')

var panel_tint := Color.TRANSPARENT:
	set(value):
		panel_tint = value
		ThemeManager.panel_tint = value
		value_changed.emit('panel_tint')

var button_tint := Color.TRANSPARENT:
	set(value):
		button_tint = value
		ThemeManager.button_tint = value
		value_changed.emit('button_tint')

#endregion

#region ui settings

var grid_item_size:float = 175
## The maximum number of items allowed in the queue at once.
var queue_size_limit:int = 150:
	set(value):
		queue_size_limit = value
		value_changed.emit('queue_size_limit')

## Image detail for album & artist covers.
## Resets cached album cover images when set.
var image_detail:int = image_detail_values[0]:
	set(value):
		image_detail = value
		for album:DBAlbum in LibraryManager.get_albums_sorted():
			if not album: continue
			album._cover = null
		value_changed.emit('image_detail')

#endregion

#region audio settings

var replay_gain_mode := ReplayGainMode.Album
var replay_gain_preamp:float = 0.0

#endregion

#region api settings

var fetch_lyrics:bool = true
var fetch_artist_cover:bool = false
var fetch_album_cover:bool = false
var send_track_finished_notif:bool = true
var send_library_scan_finished_notif:bool = true

#endregion


#region sorting data

var folded_sections: PackedStringArray

## Global search term.
var search_term:String = ''
## Artists tab sort mode.
var artist_sort_mode := DBLibrary.ArtistSortMode.title

## Artists tab ascend mode.
var artist_ascend_mode:bool = true:
	set(value):
		artist_ascend_mode = value
		value_changed.emit('artist_ascend_mode')

## Albums tab sort mode.
var album_sort_mode := DBLibrary.AlbumSortMode.title:
	set(value):
		album_sort_mode = value
		value_changed.emit('album_sort_mode')

## Albums tab ascend mode.
var album_ascend_mode:bool = true:
	set(value):
		album_ascend_mode = value
		value_changed.emit('album_ascend_mode')

## Tracks tab sort mode.
var track_sort_mode := DBLibrary.TrackSortMode.title:
	set(value):
		track_sort_mode = value
		value_changed.emit('track_sort_mode')

## Tracks tab ascend mode.
var track_ascend_mode:bool = true:
	set(value):
		track_ascend_mode = value
		value_changed.emit('track_ascend_mode')

var landing_page:String = '':
	set(value):
		landing_page = value
		value_changed.emit('landing_page')

var last_tab:String = 'albums':
	set(value):
		last_tab = value
		value_changed.emit('last_tab')

var right_sidebar_tab:String = '':
	set(value):
		right_sidebar_tab = value
		value_changed.emit('right_sidebar_tab')

var tab_content_split := PackedInt32Array():
	set(value):
		tab_content_split = value
		value_changed.emit('tab_content_split')

var artists_tab_scroll_value:float = 0
var albums_tab_scroll_value:float = 0
var tracks_tab_scroll_value:float = 0

#endregion

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
		{
			'type': 'button',
			'text': 'Show In Files',
			'icon': SessionManager.get_icon('folder'),
		},
	]),
}

#endregion

#region timers

var auto_scan_timer := Timer.new()

#endregion


func _ready() -> void:
	self.default_window_size = self.get_window().size
	self.current_window_size = self.default_window_size

	load_session()
	if self.theme.is_empty(): self.theme = 'UMP_DEFAULT' # Set default layout theme if none set by session file.

	# Configure auto-scan timer.
	auto_scan_timer.one_shot = false
	auto_scan_timer.autostart = true
	self.auto_scan_interval = self.auto_scan_interval
	auto_scan_timer.timeout.connect(LibraryManager.scan_all_libraries)
	self.add_child(auto_scan_timer)


func reload_main_scene() -> void:
	var main_scene_ = SessionManager.get_layout_theme_scene('Main/main')
	var main_scene_instance:Node = main_scene_.instantiate()
	var tree:SceneTree = self.get_tree()
	tree.change_scene_to_node.call_deferred(main_scene_instance)
	SessionManager.main_scene = main_scene_instance


func get_accent_color() -> Color:
	var accent: Color

	match SessionManager.accent_mode:
		SessionManager.AccentMode.System:
			accent = DisplayServer.get_accent_color()
		SessionManager.AccentMode.Dynamic:
			if not PlayerManager.queue.is_empty():
				accent = PlayerManager.get_current_track().album.get_album_dominant_color()
			else:
				accent = ThemeManager.accent_color
		SessionManager.AccentMode.Custom:
			accent = SessionManager.custom_accent

	return accent


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
	var data = import_config(session_file_path)
	if data is not Dictionary: return

	# Load libraries.
	LibraryManager.load_libraries()

	# Load queue.
	var raw_queue = data.get('queue')
	var tracks:Array[DBTrack] = []
	if raw_queue is Array:
		for id in raw_queue:
			if id is not String: continue
			var track = DBTrack.from_id(id)
			if track: tracks.append(track)
	PlayerManager.set_queue(tracks)

	# Set queue position.
	var raw_queue_position = data.get('queue_position')
	if (raw_queue_position is int or raw_queue_position is float) && raw_queue_position != -1:
		PlayerManager.set_current_track(int(raw_queue_position), false)

	# Set track progress.
	var raw_track_progress = data.get('track_progress')
	if raw_track_progress is float:
		PlayerManager.set_track_progress(raw_track_progress)

	# Set volume.
	var raw_volume = data.get('volume')
	if raw_volume is float:
		PlayerManager.volume = raw_volume

	var raw_auto_queue_start_index = data.get('auto_queue_start_index')
	if (raw_auto_queue_start_index is int or raw_auto_queue_start_index is float) && raw_auto_queue_start_index != -1:
		PlayerManager.auto_queue_start_index = int(raw_auto_queue_start_index)

	session_loaded.emit()
	MiniLog.info('Session loaded.', SessionManager)


## Save the current session to disk.
func save_session() -> void:
	var data = {
		'library_order': PackedStringArray(),
		'queue': [],
		'queue_position': PlayerManager.queue_position,
		'auto_queue_start_index': PlayerManager.auto_queue_start_index,
		'track_progress': PlayerManager.track_progress,
		'volume': PlayerManager.volume,
	}

	# Sync library order/visibility & save changed libraries.
	self.library_order.clear()
	for library:DBLibrary in LibraryManager.libraries:
		self.library_order.append(library.id)
		if library.changed: library.save()

	# Set data properties.
	for i in property_data:
		data.set(i[0], self.get(i[0]))

	# Set data queue.
	for track:DBTrack in PlayerManager.queue:
		data.queue.append(track.as_id())

	# Write file.
	var file := FileAccess.open(session_file_path, FileAccess.WRITE)
	var json = JSON.stringify(A2J.to_json(data), '\t', true, true)
	file.store_string(json)
	file.close()


func import_config(path:String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		file.close()
		return {}
	var data = A2J.from_json(JSON.parse_string(file.get_as_text()))
	file.close()
	if data == null: return {}

	# Apply properties.
	for i in property_data:
		var data_entry = data.get(i[0])
		if data_entry == null: continue
		if typeof(data_entry) == TYPE_FLOAT && TYPE_INT in i[1] && TYPE_FLOAT not in i[1]:
			data_entry = int(data_entry)
		if typeof(data_entry) in i[1]:
			set(i[0], data_entry)

	return data


## Exports preferences based on [param export_sections].
func export_config(path:String='user://session_export.json', export_sections:Array[String]=[]) -> void:
	var allowed_properties: PackedStringArray
	for section:Array in self.sections:
		if section[0] not in export_sections: continue
		for property:String in section[1]:
			allowed_properties.append(property)

	# Set data properties.
	var data = {}
	for i in property_data:
		if i[0] not in allowed_properties: continue
		data.set(i[0], self.get(i[0]))

	# Write file.
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json = JSON.stringify(A2J.to_json(data), '\t', true, true)
		file.store_string(json)
		file.close()


func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		current_window_size = get_window().size
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_session()
		get_tree().quit()
