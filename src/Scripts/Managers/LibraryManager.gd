## Static class for managing an audio library.
class_name LibraryManager extends RefCounted

const minilog_importance := MiniLog.Importance.High

static var a2j_ruleset:Dictionary[String,Dictionary] = {
	'@global': {
		'exclude_private_properties': true,
		'exclude_default_values': true,
		'automatic_resource_references': true,
		'instantiator_arguments': {
			'DBTrack': [null, {}],
			'DBAlbum': [null, {}],
			'DBArtist': [null, {}],
		},
		'class_exclusions': ['GDScript'],
	},
	'DBLibrary': {
		'property_exclusions': ['currently_updating'],
	},
	'DBArtist': {
		'property_exclusions': [],
	},
	'DBAlbum': {
		'property_exclusions': [],
	},
	'DBTrack': {
		'property_exclusions': [],
	},
}
const valid_audio_extensions:Array[String] = ['wav','ogg','mp3','flac']
const placeholder_meta:String = 'None found'
const libraries_path:String = 'user://libraries/'
static var lyrics_path:String = OS.get_user_data_dir()+'/lyrics'
static var image_cache_path:String = OS.get_user_data_dir()+'/image_cache'
static var artist_image_cache:String = image_cache_path+'/artist_covers'
static var out_path:String = OS.get_user_data_dir()+'/out'

static var libraries:Array[DBLibrary] = []


static func load_libraries() -> void:
	# Load all libraries from user data.
	DirAccess.make_dir_recursive_absolute(libraries_path)
	FileUtils.walk_dir(libraries_path, func(path:String) -> void:
		if path.get_extension().to_lower() == 'json':
			var file := FileAccess.open(path, FileAccess.READ)
			if not file:
				MiniLog.err('Unable to load library from "%s". Skipping library.' % path, LibraryManager)
				return
			var json = JSON.parse_string(file.get_as_text())
			var library = A2J.from_json(json, a2j_ruleset)
			if library is not DBLibrary:
				MiniLog.err('Unable to parse library from "%s". Skipping library.' % path, LibraryManager)
				return
			library.currently_updating = false
			libraries.append(library)
			MiniLog.info('Loaded library $~%s~$.' % path.get_basename().split('/')[-1], LibraryManager)
	)

	await SessionManager.get_tree().create_timer(1.0).timeout


## Rescans all libraries, in order.
static func scan_all_libraries() -> void:
	var last:DBLibrary = null
	var index:int = 0
	for library:DBLibrary in libraries:
		if not last:
			library.refresh(true)
		else:
			last.scan_finished.connect(_on_last_scan_finished.bind(library, last, index))
			index += 1
		last = library


static func _on_last_scan_finished(library:DBLibrary, last:DBLibrary, index:int):
	await SessionManager.get_tree().create_timer(1.0).timeout
	if library: library.refresh(true)
	var callable = last.scan_finished.get_connections()[index].callable
	last.scan_finished.disconnect(callable)


static func save_libraries() -> void:
	# Remove previously saved library files.
	for file_path:String in DirAccess.get_files_at(libraries_path):
		if file_path.get_extension().to_lower() != 'json': continue
		DirAccess.remove_absolute(libraries_path+file_path)

	# Save libraries.
	var index:int = -1
	for library:DBLibrary in libraries:
		index += 1
		library.save(str(index)+' ')


## Returns the [DBLibrary] or [code]null[/code] if none found.
static func get_library(id:String) -> DBLibrary:
	for library:DBLibrary in libraries:
		if library.id == id: return library
	return null


## Returns the [DBTrack] that matches the [param uid].
static func get_track_from_uid(uid:String) -> DBTrack:
	var parts:PackedStringArray = uid.split(':')
	if parts.size() != 7: return null
	var library_id:String = parts[0]
	var library := get_library(library_id)
	if library == null: return null
	# Check UID for all tracks in the library.
	for track:DBTrack in library.tracks:
		if not track: continue
		if track.as_uid() == uid: return track

	return null


## Returns a sorted array of [DBArtist] objects.
## Will always sort ascending. Use [code]Array.reverse[/code] method to make the array descending.
static func get_artists_sorted(sort_mode:=DBLibrary.ArtistSortMode.title) -> Array[DBArtist]:
	var result:Array[DBArtist] = []
	for library:DBLibrary in libraries:
		if library.hidden: continue
		result.append_array(library.get_artists_sorted(sort_mode))
	return result


static func get_albums_sorted(sort_mode:=DBLibrary.AlbumSortMode.title) -> Array[DBAlbum]:
	var result:Array[DBAlbum] = []
	for library:DBLibrary in libraries:
		if library.hidden: continue
		result.append_array(library.get_albums_sorted(sort_mode))
	return result


static func get_tracks_sorted(sort_mode:=DBLibrary.TrackSortMode.title) -> Array[DBTrack]:
	var result:Array[DBTrack] = []
	for library:DBLibrary in libraries:
		if library.hidden: continue
		result.append_array(library.get_tracks_sorted(sort_mode))
	return result


## Returns a dictionary of [DBAlbum] objects with the genre as the key.
## Will always sort ascending. Use [code]Array.reverse[/code] method to make the array descending.
static func get_genres_sorted() -> Dictionary[String,Array]:
	var result:Dictionary[String,Array] = {}
	for album:DBAlbum in get_albums_sorted():
		for genre in album.genres:
			result.get_or_add(genre, [])
			result[genre].append(album)
		if album.genres.is_empty():
			result.get_or_add('No genre', [])
			result['No genre'].append(album)

	return result


static func wipe_image_cache() -> void:
	FileUtils.walk_dir(image_cache_path, func(path:String) -> void:
		DirAccess.remove_absolute(path)
	,Callable())


static func wipe_lyrics() -> void:
	FileUtils.walk_dir(lyrics_path, func(path:String) -> void:
		DirAccess.remove_absolute(path)
	,Callable())


## Returns & recalculates the total bytes of the user data folder.
static func get_user_data_size() -> int:
	var total:Array[int] = [0]

	FileUtils.walk_dir(OS.get_user_data_dir(), func(file_path:String) -> void:
		total[0] += FileAccess.get_size(file_path)
	,func(_dir_path)->void:pass)

	return total[0]


## Returns the total bytes of the library.
static func get_library_size() -> int:
	var total:int = 0
	return total


static func load_audio(path:String) -> AudioStream:
	var extension:String = path.split('.')[-1].to_lower()
	if extension not in LibraryManager.valid_audio_extensions: return null
	if not FileAccess.file_exists(path): return null
	var audio_stream: AudioStream
	if extension == 'wav':
		audio_stream = AudioStreamWAV.load_from_file(path, {
			'compress_mode': 0,
		})
	elif extension == 'mp3':
		audio_stream = AudioStreamMP3.load_from_file(path)
	elif extension == 'ogg':
		audio_stream = AudioStreamOggVorbis.load_from_file(path)
	elif extension == 'flac':
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			audio_stream = AudioStreamFLAC.new()
			if audio_stream:
				audio_stream.data = file.get_buffer(file.get_length())
				if audio_stream.data.is_empty(): # Data didn't apply, an error occured.
					MiniLog.err('Could not load FLAC stream "$~%s~$". Only 2 channel FLACs are supported.' % path, LibraryManager)
					return null

	MiniLog.pro('Loaded audio stream from "$~%s~$".' % path, LibraryManager)
	return audio_stream
