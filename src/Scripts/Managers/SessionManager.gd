## Manage the current session.
extends Node

enum VisualizerMode {
	OFF,
	GLOW,
	BAR,
}

enum LayoutTheme {
	Normal,
	Rounded,
}

const layout_theme_name:Array[String] = [
	'Normal',
	'Rounded',
]

const property_data:Array[Array] = [
	['library_location',[TYPE_STRING]],
	['auto_fetch_lyrics',[TYPE_BOOL]],
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
	['layout_theme',[TYPE_INT]],
	['visualizer_mode',[TYPE_INT]],
	['dynamic_accents',[TYPE_BOOL]],
	['landing_page',[TYPE_STRING]],
]

## Emitted when the session has been loaded.
signal session_loaded
signal value_changed(property_name:String)
## Path to the session file.
const session_file_path:String = 'user://session.json'

## Do not touch this.
var data:Dictionary = {
	'queue': [],
	'queue_position': -1,
	'auto_queue_start_index': -1,
	'track_progress': 0,
	'hd_album_covers': false,
	'visualizer_mode': 0,
	'dynamic_accents': true,
	'layout_theme': 0,
}

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
var auto_fetch_lyrics:bool = true

var search_term:String = '':
	set(value):
		search_term = value
		value_changed.emit('search_term')

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

var layout_theme := LayoutTheme.Normal:
	set(value):
		layout_theme = value
		var tree:SceneTree = get_tree()
		get_tree().change_scene_to_packed(get_layout_theme_scene('main'))
		main_scene = tree.current_scene
		var init = Node.new()
		init.set_script(load('res://Themes/%s/init.gd' % layout_theme_name[value]))
		init.call('init')
		value_changed.emit('layout_theme')

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


func _ready() -> void:
	default_window_size = get_window().size
	current_window_size = default_window_size
	load_session()


func get_layout_theme_scene(scene_name:String) -> PackedScene:
	var path:String = layout_theme_name[layout_theme]
	match scene_name.to_lower():
		'main': return load('res://Themes/%s/Main/main.tscn' % path)
		'settings': return load('res://Themes/%s/Settings/settings.tscn' % path)
		'immersive player': return load('res://Themes/%s/Immersive Player/immersive_player.tscn' % path)
		'queue': return load('res://Themes/%s/Queue/queue.tscn' % path)
		'queue_card': return load('res://Themes/%s/Queue/card.tscn' % path)

		'artists': return load('res://Themes/%s/Artists/artists.tscn' % path)
		'artists_card': return load('res://Themes/%s/Artists/card.tscn' % path)
		'artist_page': return load('res://Themes/%s/Artist Page/artist_page.tscn' % path)

		'albums': return load('res://Themes/%s/Albums/albums.tscn' % path)
		'albums_card': return load('res://Themes/%s/Albums/card.tscn' % path)
		'album_page': return load('res://Themes/%s/Album Page/album_page.tscn' % path)

		'tracks': return load('res://Themes/%s/Tracks/tracks.tscn' % path)
		'tracks_card': return load('res://Themes/%s/Tracks/card.tscn' % path)
		'tracks_placeholder_card': return load('res://Themes/%s/Tracks/placeholder_card.tscn' % path)

		'genres': return load('res://Themes/%s/Genres/genres.tscn' % path)
		'genres_card': return load('res://Themes/%s/Genres/card.tscn' % path)

	return null


## Load session from disk.
## May override current playing track in PlayerManager.
func load_session() -> void:
	var file := FileAccess.open(session_file_path, FileAccess.READ)
	if file == null: return
	var stored_data = JSON.parse_string(file.get_as_text())
	if stored_data == null: return
	data = stored_data

	for i in property_data:
		var data_entry = data.get(i[0])
		if typeof(data_entry) == TYPE_FLOAT && TYPE_INT in i[1] && TYPE_FLOAT not in i[1]:
			data_entry = int(data_entry)
		if typeof(data_entry) in i[1]:
			self.set(i[0], data_entry)

	PlayerManager.queue.clear()
	var raw_queue = data.get('queue')
	if raw_queue is Array:
		for item in raw_queue:
			if item is not Dictionary: continue
			var artist_name = item.get('artist')
			if artist_name is String && not artist_name.is_empty():
				var artist := DBArtist.new_or_reuse(artist_name)
				var album_name = item.get('album')
				if album_name is String && not album_name.is_empty():
					var album := DBAlbum.new_or_reuse(artist, album_name)
					var track_number = item.get('number')
					if (track_number is int or track_number is float) && track_number != -1:
						track_number = int(track_number)
						PlayerManager.add_to_queue(DBTrack.new_or_reuse(artist, album, track_number))

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


## Save the current session to disk.
func save_session() -> void:
	data = {
		'queue': [],
		'queue_position': PlayerManager.queue_position,
		'auto_queue_start_index': PlayerManager.auto_queue_start_index,
		'track_progress': PlayerManager.track_progress,
		'volume': PlayerManager.get_volume(),
	}

	for i in property_data:
		data.set(i[0], self.get(i[0]))

	for track:DBTrack in PlayerManager.queue:
		data.queue.append({
			'artist': track.artist.name,
			'album': track.album.name,
			'number': track.number,
		})

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
