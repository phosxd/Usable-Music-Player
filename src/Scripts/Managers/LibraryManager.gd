## Static class for managing an audio library.
class_name LibraryManager extends RefCounted

enum ArtistSortMode {
	## Sort by title in alphabetical order.
	TITLE,
}

enum AlbumSortMode {
	## Sort by title in alphabetical order.
	TITLE,
	## Sort by artist title in alphabetical order.
	ARTIST,
	## Sort by year released.
	YEAR,
	## Sort by genre.
	GENRE,
}

enum TrackSortMode {
	## Sort by title in alphabetical order.
	TITLE,
	## Sort by album title in alphabetical order.
	ALBUM,
	## Sort by artist title in alphabetical order.
	ARTIST,
	## Sort by year released.
	YEAR,
	## Sort by genre.
	GENRE,
	## Sort by track number.
	NUMBER,
	## Sort by track length.
	LENGTH,
}

const valid_audio_extensions:Array[String] = ['wav','ogg','mp3','flac']
const db_cache_path:String = 'user://database.txt'
const placeholder_meta:String = 'None found'
static var lyrics_path:String = OS.get_user_data_dir()+'/lyrics'
static var image_cache_path:String = OS.get_user_data_dir()+'/image_cache'
static var out_path:String = OS.get_user_data_dir()+'/out'


static var database:Dictionary = {
	'track_count': 0,
	'library_size': 0,
	'artists': {},
}

static var currently_updating:bool = false


## Returns a sorted array of [DBArtist] objects.
## Will always sort ascending. Use [code]Array.reverse[/code] method to make the array descending.
static func get_artists_sorted(sort_mode:=ArtistSortMode.TITLE) -> Array[DBArtist]:
	var result:Array[DBArtist] = []
	for artist_name:String in database.get('artists',{}):
		result.append(DBArtist.new_or_reuse(artist_name))

	match sort_mode:
		ArtistSortMode.TITLE:
			result.sort_custom(func(a:DBArtist, b:DBArtist) -> bool:
				return a.name < b.name
			)

	return result


static func get_albums_sorted(sort_mode:=AlbumSortMode.TITLE) -> Array[DBAlbum]:
	var result:Array[DBAlbum] = []
	for artist:DBArtist in get_artists_sorted():
		for album_name:String in artist.album_names:
			result.append(DBAlbum.new_or_reuse(artist, album_name))

	match sort_mode:
		AlbumSortMode.TITLE:
			result.sort_custom(func(a:DBAlbum, b:DBAlbum) -> bool:
				return a.name < b.name
			)
		AlbumSortMode.ARTIST:
			result.sort_custom(func(a:DBAlbum, b:DBAlbum) -> bool:
				return a.artist.name < b.artist.name
			)
		AlbumSortMode.YEAR:
			result.sort_custom(func(a:DBAlbum, b:DBAlbum) -> bool:
				return a.year.to_int() < b.year.to_int()
			)
		AlbumSortMode.GENRE:
			result.sort_custom(func(a:DBAlbum, b:DBAlbum) -> bool:
				return a.genre < b.genre
			)

	return result


## Returns a dictionary of [DBAlbum] objects with the genre as the key.
## Will always sort ascending. Use [code]Array.reverse[/code] method to make the array descending.
static func get_genres_sorted() -> Dictionary[String,Array]:
	var result:Dictionary[String,Array] = {}
	for album:DBAlbum in get_albums_sorted():
		result.get_or_add(album.genre, [])
		result[album.genre].append(album)

	return result


static func get_tracks_sorted(sort_mode:=TrackSortMode.TITLE) -> Array[DBTrack]:
	var result:Array[DBTrack] = []
	for album:DBAlbum in get_albums_sorted():
		for track_number:int in album.track_count:
			var track:DBTrack = album.get_track(track_number)
			if track: result.append(track)

	match sort_mode:
		TrackSortMode.TITLE:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.name < b.name
			)
		TrackSortMode.ALBUM:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.album.name < b.album.name
			)
		TrackSortMode.ARTIST:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.album.artist.name < b.album.artist.name
			)
		TrackSortMode.YEAR:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.album.year.to_int() < b.album.year.to_int()
			)
		TrackSortMode.GENRE:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.album.genre < b.album.genre
			)
		TrackSortMode.NUMBER:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.number < b.number
			)
		TrackSortMode.LENGTH:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.length < b.length
			)

	return result


## Rescans the track & updates the database accordingly.
## Returns the updated DBTrack.
static func rescan_track(track:DBTrack, custom_data:Dictionary={}) -> DBTrack:
	database.artists[track.artist.name].albums[track.album.name].tracks.set(track.number, null)
	database.library_track_count -= 1
	var track_size = FileAccess.get_size(track.path)
	if track_size > 0: database.library_size -= track_size
	index_file(track.path, track.number, custom_data)
	save_database()

	DBTrack.update(track.artist, track.album, track.number)
	return DBTrack.new_or_reuse(track.artist, track.album, track.number)


static func wipe_database() -> void:
	database.set('artists', {})
	database.set('track_count', 0)
	database.set('library_size', 0)
	database.erase('timestamp')


static func wipe_image_cache() -> void:
	FileUtils.walk_dir(image_cache_path, func(path:String) -> void:
		DirAccess.remove_absolute(path)
	,Callable())


static func wipe_lyrics() -> void:
	DirAccess.remove_absolute(lyrics_path)


## Returns the total bytes of the database & image cache.
static func get_cache_size() -> int:
	var total:Array[int] = [0]
	# Database cache.
	total[0] += FileAccess.get_file_as_bytes(db_cache_path).size()
	# Image cache.
	FileUtils.walk_dir(image_cache_path, func(path:String) -> void:
		total[0] += FileAccess.get_file_as_bytes(path).size()
	,Callable())

	return total[0]


## Returns the total bytes of the library.
static func get_library_size() -> int:
	return database.library_size


static func save_database() -> void:
	var file := FileAccess.open(db_cache_path, FileAccess.WRITE)
	if file == null:
		printerr('Failed to save database.')
		return
	var bytes:PackedByteArray = var_to_bytes(database)
	file.store_buffer(bytes)
	file.close()


static func load_library_from_cache() -> void:
	var file := FileAccess.open(db_cache_path, FileAccess.READ)
	if file == null: return
	var bytes:PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	var result = bytes_to_var(bytes)
	if result is Dictionary:
		database = result


static func load_library(root_path:String, callback:Callable) -> void:
	currently_updating = true
	SessionManager.library_location = root_path
	LibraryManager.wipe_database()
	LibraryManager.wipe_image_cache()
	database.location = root_path
	database.set('timestamp', Time.get_datetime_string_from_system(true, true))
	## GDScript trickery.
	callback = callback
	# Load library threaded.
	_load_library(root_path, func(_result) -> void:
		currently_updating = false
		save_database()
		load_library_from_cache()
		if callback && not callback.is_null() && callback.get_object() && callback.is_valid(): callback.call()
	)


static func _load_library(root_path:String, callback:Callable) -> void:
	var root_dir := DirAccess.open(root_path)
	if root_dir == null: return
	ThreadHelper.create_thread((func() -> void:
		FileUtils.walk_dir(root_path, func(path:String) -> void:
			LibraryManager.index_file(path)
			LibraryManager.database.library_size += FileAccess.get_file_as_bytes(path).size()
		,Callable())
	),callback)


static func index_file(path:String, track_number_override:int=-1, custom_data:Dictionary={}) -> void:
	var extension:String = path.split('.')[-1].to_lower()
	if extension not in LibraryManager.valid_audio_extensions: return
	# Load audio file.
	var audio_stream = load_audio(path)
	if audio_stream is not AudioStream: return
	audio_stream = audio_stream as AudioStream

	# Grab metadata.
	DirAccess.make_dir_recursive_absolute(out_path)
	var exit_code:int = CLI.execute('interface', ['get_audio_meta', path, out_path])
	if exit_code != OK: return
	var metadata = JSON.parse_string(FileAccess.get_file_as_string(out_path+'/out.txt'))
	if metadata is not Dictionary: return
	var artist:String = metadata.get('artist','').replace('\n','')
	var album:String = metadata.get('album','').replace('\n','')
	if artist.is_empty(): artist = placeholder_meta
	if album.is_empty(): album = placeholder_meta

	var cover_path:String = image_cache_path+'/%s.jpg' % album.replace('/','_')
	DirAccess.make_dir_recursive_absolute(image_cache_path)
	DirAccess.rename_absolute(out_path+'/out.jpg', cover_path)
	var image = Image.load_from_file(cover_path)
	image = ImageTexture.create_from_image(image)

	var track_title:String = metadata.get('title','').replace('\n','')
	var track_number:int = metadata.get('track',0)
	var year:String = metadata.get('year','').replace('\n','')
	if track_title.is_empty(): track_title = path.split('/')[-1]
	if track_title.is_empty(): track_title = placeholder_meta
	if year.is_empty(): year = placeholder_meta

	# Add to database.
	var db_artist:Dictionary = database.artists.get_or_add(artist, {
		#'cover': fetch_artist_cover(artist),
		'albums': {},
	})
	@warning_ignore('incompatible_ternary')
	var db_album:Dictionary = db_artist.albums.get_or_add(album, {
		'year': metadata.get('year',placeholder_meta),
		'genre': metadata.get('genre',placeholder_meta),
		'cover': cover_path,
		'tracks': [],
		'palette': DBAlbum.calculate_colors(image),
	})
	if track_number > db_album.tracks.size(): db_album.tracks.resize(track_number)
	var track_data = {
		'title': track_title,
		'length': audio_stream.get_length(),
		'channels': str(metadata.get('channels',-1)),
		'bit_rate': str(metadata.get('bitrate',-1)),
		'sample_rate': str(metadata.get('samplerate',-1)),
		'bpm': metadata.get('bpm'),
		'copyright': metadata.get('copyright'),
		'urls': metadata.get('urls'),
		'comment': metadata.get('comment'),
		'path': path,
		'last_accessed': FileAccess.get_access_time(path),
		'last_modified': FileAccess.get_modified_time(path),
	}
	track_data.merge(custom_data, true)
	if track_number_override != -1:
		db_album.tracks.set(track_number_override, track_data)
	elif track_number > 0:
		db_album.tracks.set(track_number-1, track_data)
	else:
		db_album.tracks.append(track_data)

	database.track_count += 1


static func load_audio(path:String) -> AudioStream:
	var extension:String = path.split('.')[-1].to_lower()
	if extension not in LibraryManager.valid_audio_extensions: return null
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
		audio_stream = AudioStreamFLAC.new()
		audio_stream.data = file.get_buffer(file.get_length())

	print('Loaded: '+path)
	return audio_stream


#static func fetch_artist_cover(artist_name:String) -> ImageTexture:
	#'https://webservice.fanart.tv/{version}/{resource}/{id}?api_key='
	#'7e7651b46fca21ce80d7ac1863093b69'
