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
	'DBArtist': {
		'property_exclusions': ['valid'],
	},
	'DBAlbum': {
		'property_exclusions': ['valid'],
	},
	'DBTrack': {
		'property_exclusions': ['valid'],
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
### If true, the database is currently updating.
#static var currently_updating:bool = false
### Array of image paths already calculated & processed.
#static var updated_images:Array[String] = []


static func load_libraries() -> void:
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
			libraries.append(library)
			MiniLog.info('Loaded library $~%s~$.' % path.get_basename().split('/')[-1], LibraryManager)
	)


static func save_libraries() -> void:
	# Remove previously saved library files.
	for file_path:String in DirAccess.get_files_at(libraries_path):
		if file_path.get_extension().to_lower() != 'json': continue
		DirAccess.remove_absolute(libraries_path+file_path)

	# Save libraries.
	for library:DBLibrary in libraries:
		var ajson = A2J.to_json(library, a2j_ruleset)
		if ajson is not Dictionary:
			MiniLog.err('Failed to save library "%s".' % library.id, LibraryManager)
			continue
		var file := FileAccess.open(libraries_path+library.id+'.json', FileAccess.WRITE)
		file.store_string(JSON.stringify(ajson))
		file.close()


## Returns the [DBLibrary] or [code]null[/code] if none found.
static func get_library(id:String) -> DBLibrary:
	for library:DBLibrary in libraries:
		if library.id == id: return library
	return null


#static func add_library(path:String) -> DBLibrary:
	#var library := DBLibrary.new()
	#library.path = path
#
	#var dump:Array = Metadata.dump_audio_meta(path)
	#var parsed_images:Array[String] = []
	#for entry in dump:
		#if entry is not Dictionary: continue
		#_parse_entry(library, entry, parsed_images)
#
	#libraries.append(library)
	#return library


## Returns the [DBTrack] that matches the [param uid].
static func get_track_from_uid(uid:String) -> DBTrack:
	var parts:PackedStringArray = uid.split('.')
	if parts.size() != 7: return null
	var library_id:String = parts[0]
	var library := get_library(library_id)
	if library == null: return null
	# Check UID for all tracks in the library.
	for track:DBTrack in library.tracks:
		if track.as_uid() == uid: return track

	return null


## Creates an artist with the given ID & data. Returns the newly created [DBArtist] or [code]null[/code] if failed to create.
#static func add_artist(id:String, data:Dictionary) -> DBArtist:
	#var split_id:PackedStringArray = id.split(':')
	#var library_name:String = split_id[0]
	#var item_id:String = split_id[1]
	#var library:DBLibrary = get_library(library_name)
	#var artist := DBArtist.new(artist_name, data)
	#database.artists.set(artist_name, artist)
	#return artist


## Can return [code]null[/code] if not found.
#static func get_artist(artist_name:String) -> DBArtist:
	#var artist = database.artists.get(artist_name)
	#if artist is DBArtist: return artist
	#else: return null


## Removes the artist & all albums & tracks under the artist.
#static func remove_artist(artist_name:String) -> void:
	#var artist = database.artists.get(artist_name)
	#if artist is DBArtist:
		#artist.valid = false
		## Remove all albums under artist.
		#for album in artist.albums.values():
			#album.remove()
	#database.artists.erase(artist_name)


## Returns an existing album or a new one if it doesn't exist.
## Can return [code]null[/code] if failed.
#static func add_album(artist:DBArtist, album_name:String, data:Dictionary) -> DBAlbum:
	#if not artist: return null
	#var old_album = artist.albums.get(album_name)
	#if old_album is DBAlbum: return old_album
	#else:
		#var album := DBAlbum.new(artist, album_name, data)
		#artist.albums.set(album_name, album)
		#return album


## Can return [code]null[/code] if not found.
#static func get_album(artist:DBArtist, album_name:String) -> DBAlbum:
	#if not artist: return null
	#var album = artist.albums.get(album_name)
	#if album is DBAlbum: return album
	#else: return null


## Removes the album & all tracks under the album.
#static func remove_album(artist:DBArtist, album_name:String) -> void:
	#if not artist: return
	#var album = artist.albums.get(album_name)
	#if album is DBAlbum:
		#album.valid = false
		## Remove all tracks under album.
		#for track in album.tracks.values():
			#track.remove()


## Returns an existing track or a new one if it doesn't exist.
## Can return [code]null[/code] if failed.
#static func add_track(album:DBAlbum, track_path:String, data:Dictionary) -> DBTrack:
	#if not album: return null
	#var old_track = album.tracks.get(track_path)
	#if old_track is DBTrack: return old_track
	#else:
		#var track := DBTrack.new(album, track_path, data)
		#album.tracks.set(track_path, track)
		#database.tracks.set(track_path, track)
		#return track


## Can return [code]null[/code] if not found.
#static func get_track(track_path:String) -> DBTrack:
	#var track = database.tracks.get(track_path)
	#if track is not DBTrack: return null
	#return track


## Removes the track.
#static func remove_track(track_path:String) -> void:
	#var track = database.tracks.get(track_path)
	#if track is DBTrack:
		#track.valid = false
		#track.album.tracks.erase(track_path)
	#database.tracks.erase(track_path)


## Returns a sorted array of [DBArtist] objects.
## Will always sort ascending. Use [code]Array.reverse[/code] method to make the array descending.
static func get_artists_sorted(sort_mode:=DBLibrary.ArtistSortMode.title) -> Array[DBArtist]:
	var result:Array[DBArtist] = []
	for library:DBLibrary in libraries:
		result.append_array(library.get_artists_sorted(sort_mode))
	return result


static func get_albums_sorted(sort_mode:=DBLibrary.AlbumSortMode.title) -> Array[DBAlbum]:
	var result:Array[DBAlbum] = []
	for library:DBLibrary in libraries:
		result.append_array(library.get_albums_sorted(sort_mode))
	return result


static func get_tracks_sorted(sort_mode:=DBLibrary.TrackSortMode.title) -> Array[DBTrack]:
	var result:Array[DBTrack] = []
	for library:DBLibrary in libraries:
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


#static func rescan_artist(artist:DBArtist, update_db:bool=true) -> void:
	#var all_albums = artist.albums.values()
	#var all_tracks:Dictionary[String,Array] = {}
	#for album:DBAlbum in all_albums:
		#all_tracks.set(album.name, album.tracks.values())
#
	#artist.remove()
#
	#for album:DBAlbum in all_albums:
		#rescan_album(album, false, all_tracks[album.name])
#
	#if update_db:
		#save_database()
#
#
#static func rescan_album(album:DBAlbum, update_db:bool=true, all_tracks:Array[DBTrack]=[]) -> void:
	#if all_tracks.size() == 0:
		#for track:DBTrack in album.tracks.values():
			#all_tracks.append(track)
#
	#album.remove()
#
	## Rescan all tracks.
	#for track:DBTrack in all_tracks:
		#LibraryManager.rescan_track(track, '', false)
#
	#if update_db:
		#save_database()
#
#
### Rescans the track & updates the database accordingly.
### Does not update the database file only the database in memory.
#static func rescan_track(track:DBTrack, path:String='', update_db:bool=true) -> void:
	#if not track && path.is_empty(): return
	#if track:
		#path = track.path
		#track.remove()
#
	#if not FileAccess.file_exists(path): return
#
	## Get metadata from track at path & index it.
	#var output:Array = []
	#var err:int = CLI.execute('interface', ['get_audio_meta', path, image_cache_path], output)
	#if err != Error.OK:
		#MiniLog.err('Could not rescan track at "$~%s~$" with error "$!!%s!!$".' % [path, output[0]], LibraryManager)
		#return
	#if output.size() > 0 && output[0] is String:
		#var meta = JSON.parse_string(output[0])
		#if meta is not Dictionary: return
		#LibraryManager._index(meta)
#
	#if update_db:
		#save_database()


#static func scan_for_changes() -> void:
	#LibraryManager.currently_updating = true
#
	#var found_paths:Array[String] = []
	#FileUtils.walk_dir(SessionManager.library_location, func(file_path:String) -> void:
		#var ext:String = file_path.split('.')[-1].to_lower()
		#if ext not in valid_audio_extensions: return
		#found_paths.append(file_path)
		## Get track.
		#var track = database.tracks.get(file_path)
		## Compare last modified time.
		#var old_last_modified_time:int = -1
		#if track is DBTrack: old_last_modified_time = track.last_modified_time
		#var last_modified_time:int = FileAccess.get_modified_time(file_path)
		## Rescan if modified.
		#if old_last_modified_time != last_modified_time:
			#rescan_track(null, file_path)
	#,func(_dir_path:String) -> void: pass)
#
	#for path:String in database.tracks:
		#if path not in found_paths:
			#remove_track(path)
#
	#LibraryManager.currently_updating = false
	#if SessionManager.send_library_scan_finished_notif: SystemNotif.send('', 'Finished scanning for changes.')
#
#
#static func wipe_database() -> void:
	#database.set('artists', {})
	#database.set('tracks', {})
	#database.erase('timestamp')


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


## Save the [code]database[/code] as AJSON to the [code]db_cache_path[/code].
#static func save_database() -> void:
	#var file := FileAccess.open(db_cache_path, FileAccess.WRITE)
	#if file == null:
		#MiniLog.err('Failed to open DB Cache Path to write database.', LibraryManager)
		#return
	#var json = A2J.to_json(database, a2j_ruleset)
	#file.store_string(JSON.stringify(json, '', true, true))
	#file.close()


## Loads the saved database from [code]db_cache_path[/code].
#static func load_database() -> void:
	#MiniLog.info('Loading library from cache.', LibraryManager)
	#var text:String = FileAccess.get_file_as_string(db_cache_path)
	#if text.is_empty(): return
#
	#var json = JSON.parse_string(text)
	#if json is Dictionary:
		#database = A2J.from_json(json, a2j_ruleset)


## Generates the database from audio files in the [param root_path].
## Calls [param callback] with no arguments when finished.
#static func generate_database(root_path:String, callback:Callable) -> void:
	#LibraryManager.currently_updating = true
	#SessionManager.library_location = root_path
	#LibraryManager.wipe_database()
	#LibraryManager.wipe_image_cache()
	#LibraryManager.wipe_lyrics()
	#database.set('timestamp', Time.get_datetime_string_from_system(true, true))
	## Generate database threaded.
	#_generate_database(root_path, func(_result) -> void:
		#LibraryManager.currently_updating = false
		#save_database()
		#load_database()
		#if SessionManager.send_library_scan_finished_notif: SystemNotif.send('', 'Finished scanning library.')
		#if callback && callback.is_valid() && callback.get_object():
			#callback.call()
	#)
#
	## Update status.
	#var timer := Timer.new()
	#timer.one_shot = false
	#timer.timeout.connect(func() -> void:
		#var indexing_label = SessionManager.main_scene.get_node('%Indexing Label')
		#var indexing_status = SessionManager.main_scene.get_node('%Indexing Status')
		#if indexing_label is not Label or indexing_status is not Control:
			#timer.stop()
			#timer.queue_free()
			#return
		#indexing_status.show()
		#indexing_label.text = SessionManager.main_scene.indexing_label_template % LibraryManager.database.tracks.size()
		#if LibraryManager.currently_updating == false:
			#indexing_status.hide()
			#timer.stop()
			#timer.queue_free()
	#)
	#timer.timeout.emit()
	#SessionManager.add_child(timer)
	#timer.start(1.0)


#static func _generate_database(root_path:String, callback:Callable) -> void:
	#var root_dir := DirAccess.open(root_path)
	#if root_dir == null:
		#if callback && callback.is_valid(): callback.call(null)
		#return
#
	#updated_images.clear()
	#DirAccess.make_dir_recursive_absolute(image_cache_path)
	#DirAccess.make_dir_recursive_absolute(lyrics_path)
	#Async.create_thread((func() -> void:
		## Batch grab metadata from all audio files in the "root_path".
		#var output:Array = []
		#CLI.execute('interface', ['dump_audio_meta', root_path, image_cache_path], output)
		#if output.size() > 0 && output[0] is String:
			#var meta_dump = JSON.parse_string(output[0])
			#if meta_dump is not Array: return
			#for item in meta_dump:
				#if item is not Dictionary: continue
				#LibraryManager._index(item)
	#),callback)
	#updated_images.clear()


#static func _index(metadata:Dictionary, track_number_override:int=-1, _disc_number_override:int=-1, custom_data:Dictionary={}) -> void:
	#var path:String = metadata.get('path','')
	#if path.is_empty(): return
	#var duration:float = metadata.get('duration',0)
	#var artist_name:String = metadata.get('artist','').replace('\n','')
	#var actual_artist:String = artist_name
	#var album_name:String = metadata.get('album','').replace('\n','')
	#var album_artist:String = metadata.get('albumartist','').replace('\n','')
	#if not album_artist.is_empty(): artist_name = album_artist
	#if artist_name.is_empty():
		#artist_name = placeholder_meta
	#if album_name.is_empty(): album_name = placeholder_meta
#
	#var palette = {}
	#var cover_path:String = metadata.get('cover_path','')
	#if not cover_path.is_empty() && cover_path not in updated_images:
		#var image = Image.load_from_file(cover_path)
		#image = ImageTexture.create_from_image(image)
		#palette = DBAlbum.calculate_colors(image)
		#updated_images.append(cover_path)
#
	#var track_title:String = metadata.get('title','').replace('\n','')
	#var track_number:int = int(metadata.get('track',0))
	#if track_number_override != -1: track_number = track_number_override
	#var disc_number:int = int(metadata.get('disc',1))
	#var year:String = metadata.get('year','').replace('\n','')
	#var internal_lyrics:String = metadata.get('lyrics','')
#
	#if track_title.is_empty(): track_title = path
	#if disc_number == 0: disc_number = 1
	#if year.is_empty(): year = placeholder_meta
#
	## Add to database.
	#var artist_data:Dictionary = {
		#'albums': Dictionary({}, TYPE_STRING, '', null, TYPE_OBJECT, 'DBAlbum', DBAlbum),
	#}
	#@warning_ignore('incompatible_ternary')
	#var album_data:Dictionary = {
		#'year': metadata.get('year',placeholder_meta),
		#'genre': metadata.get('genre',placeholder_meta),
		#'cover_path': cover_path,
		#'tracks': Array([], TYPE_OBJECT, 'DBTrack', DBTrack),
		#'palette': palette,
		#'copyright': metadata.get('copyright'),
	#}
	#var track_data = {
		#'title': track_title,
		#'actual_artist': actual_artist,
		#'number': track_number,
		#'disc': disc_number,
		#'length': duration,
		#'channels': str(metadata.get('channels',-1)),
		#'bit_rate': str(metadata.get('bitrate',-1)),
		#'sample_rate': str(metadata.get('samplerate',-1)),
		#'bpm': metadata.get('bpm'),
		#'comment': metadata.get('comment'),
		#'last_modified_time': FileAccess.get_modified_time(path)
	#}
	#track_data.merge(custom_data, true)
	#var artist_entry := LibraryManager.add_artist(artist_name, artist_data)
	#var album_entry := LibraryManager.add_album(artist_entry, album_name, album_data)
	#var track_entry := LibraryManager.add_track(album_entry, path, track_data)
	#track_entry.save_lyrics(internal_lyrics)
	#MiniLog.pro('Indexed: "$~%s~$".' % path, LibraryManager)


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
