## Manage the current session.
extends Node

enum VisualizerMode {
	OFF,
	GLOW,
	BAR,
}

const property_data:Array[Array] = [
	# Track progress.
	['track_progress',[TYPE_INT]],
	# Tab data.
	['artist_sort_mode',[TYPE_INT]],
	['artist_ascend_mode',[TYPE_BOOL]],
	['album_sort_mode',[TYPE_INT]],
	['album_ascend_mode',[TYPE_BOOL]],
	['track_sort_mode',[TYPE_INT]],
	['track_ascend_mode',[TYPE_BOOL]],
	# UI settings.
	['visualizer_mode',[TYPE_INT]],
	['dynamic_accents',[TYPE_BOOL]],
]

## Emitted when the session has been loaded.
signal session_loaded
signal value_changed(property_name:String)
## Path to the session file.
const session_file_path:String = 'user://session.json'

## Do not touch this.
var data:Dictionary = {
	'track': {
		'artist': '',
		'album': '',
		'track_number': -1,
		'track_progress': 0,
	},
	'visualizer_mode': 0,
	'dynamic_accents': true,
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

## Current session track.
var track: DBTrack:
	set(value):
		track = value
		value_changed.emit('track')

## Current session track progress.
var track_progress:float = 0:
	set(value):
		track_progress = value
		value_changed.emit('track_progress')

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


func _ready() -> void:
	default_window_size = get_window().size
	current_window_size = default_window_size
	load_session()
	# Load session track into player if valid.
	if track is DBTrack && track.valid:
		var track_progress_local:float = track_progress
		PlayerManager.queue.clear()
		PlayerManager.add_to_queue(track)
		PlayerManager.set_current_track(0)
		PlayerManager.set_track_progress(track_progress_local)


## Load session from disk.
## May override current playing track in PlayerManager.
func load_session() -> void:
	var file := FileAccess.open(session_file_path, FileAccess.READ)
	if file == null: return
	var stored_data = JSON.parse_string(file.get_as_text())
	if stored_data == null: return
	data = stored_data

	var raw_track = data.get('track')
	if raw_track is Dictionary:
		var artist_name = raw_track.get('artist')
		if artist_name is String && not artist_name.is_empty():
			var artist := DBArtist.new(artist_name)
			var album_name = raw_track.get('album')
			if album_name is String && not album_name.is_empty():
				var album := DBAlbum.new(artist, album_name)
				var track_number = raw_track.get('track_number')
				if (track_number is int or track_number is float) && track_number != -1:
					track_number = int(track_number)
					track = DBTrack.new(artist, album, track_number)

	for i in property_data:
		var data_entry = data.get(i[0])
		if typeof(data_entry) == TYPE_FLOAT && TYPE_INT in i[1] && TYPE_FLOAT not in i[1]:
			data_entry = int(data_entry)
		if typeof(data_entry) in i[1]:
			self.set(i[0], data_entry)

	session_loaded.emit()


## Save the current session to disk.
func save_session() -> void:
	if track == null or track.valid == false: return
	data.set('track', {
		'artist': track.artist.name,
		'album': track.album.name,
		'track_number': track.number,
	})

	for i in property_data:
		data.set(i[0], self.get(i[0]))

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
