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
static var artist_image_cache:String = image_cache_path+'/artist_covers'
static var out_path:String = OS.get_user_data_dir()+'/out'


static var database:Dictionary = {
	'track_count': 0,
	'library_size': 0,
	'artists': {},
}
static var db_cache_size:int = 0
## If true, the database is currently updating.
static var currently_updating:bool = false
## Array of image paths already calculated & processed.
static var updated_images:Array[String] = []


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
		for disc in album.discs:
			for i in album.discs[disc]:
				var track:DBTrack = album.get_track(i, int(disc))
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
	database.artists[track.artist.name].albums[track.album.name].discs[str(track.disc)].tracks.set(track.number, null)
	database.track_count -= 1
	var track_size = FileAccess.get_size(track.path)
	if track_size > 0: database.library_size -= track_size
	_index(track.raw, track.number, -1, custom_data)
	save_database()

	DBTrack.update(track.artist, track.album, track.number, track.disc)
	return DBTrack.new_or_reuse(track.artist, track.album, track.number, track.disc)


static func wipe_database() -> void:
	db_cache_size = 0
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

	db_cache_size = total[0]
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
	database.set('timestamp', Time.get_datetime_string_from_system(true, true))
	# Load library threaded.
	_load_library(root_path, func(_result) -> void:
		currently_updating = false
		save_database()
		load_library_from_cache()
		if callback && callback.is_valid() && callback.get_object():
			callback.call()
	)

	var timer := Timer.new()
	timer.one_shot = false
	timer.timeout.connect(func() -> void:
		var indexing_label = SessionManager.main_scene.get_node('%Indexing Label')
		if indexing_label is not Label: return
		indexing_label.show()
		indexing_label.text = SessionManager.main_scene.indexing_label_template % LibraryManager.database.track_count
		if LibraryManager.currently_updating == false:
			indexing_label.hide()
			timer.stop()
			timer.queue_free()
	)
	SessionManager.add_child(timer)
	timer.start(1.0)


static func _load_library(root_path:String, callback:Callable) -> void:
	var root_dir := DirAccess.open(root_path)
	if root_dir == null:
		if callback && callback.is_valid(): callback.call(null)
		return

	updated_images.clear()
	DirAccess.make_dir_recursive_absolute(image_cache_path)
	ThreadHelper.create_thread((func() -> void:
		# Batch grab metadata from all audio files in the "root_path".
		var output:Array = []
		CLI.execute('interface', ['dump_audio_meta', root_path, image_cache_path], output)
		if output.size() > 0 && output[0] is String:
			var meta_dump = JSON.parse_string(output[0])
			if meta_dump is not Array: return
			for item in meta_dump:
				if item is not Dictionary: continue
				LibraryManager._index(item)
	),callback)


static func _index(metadata:Dictionary, track_number_override:int=-1, _disc_number_override:int=-1, custom_data:Dictionary={}) -> void:
	var path:String = metadata.get('path','')
	if path.is_empty(): return
	var duration:float = metadata.get('duration',0)
	var artist:String = metadata.get('artist','').replace('\n','')
	var actual_artist:String = artist
	var album:String = metadata.get('album','').replace('\n','')
	var album_artist:String = metadata.get('albumartist','').replace('\n','')
	if not album_artist.is_empty(): artist = album_artist
	if artist.is_empty():
		artist = placeholder_meta
	if album.is_empty(): album = placeholder_meta

	var palette = {}
	var cover_path:String = metadata.get('cover_path','')
	if not cover_path.is_empty() && cover_path not in updated_images:
		var image = Image.load_from_file(cover_path)
		image = ImageTexture.create_from_image(image)
		palette = DBAlbum.calculate_colors(image)
		updated_images.append(cover_path)

	var track_title:String = metadata.get('title','').replace('\n','')
	var track_number:int = int(metadata.get('track',0))
	if track_number_override != -1: track_number = track_number_override
	var disc_number:int = int(metadata.get('disc',1))
	var year:String = metadata.get('year','').replace('\n','')
	var internal_lyrics:String = metadata.get('lyrics','')

	if track_title.is_empty(): track_title = path
	if disc_number == 0: disc_number = 1
	if year.is_empty(): year = placeholder_meta

	# Add to database.
	var db_artist:Dictionary = database.artists.get_or_add(artist, {
		'albums': {},
	})
	@warning_ignore('incompatible_ternary')
	var db_album:Dictionary = db_artist.albums.get_or_add(album, {
		'year': metadata.get('year',placeholder_meta),
		'genre': metadata.get('genre',placeholder_meta),
		'cover': cover_path,
		'discs': {
			'1': {'tracks': []},
		},
		'palette': palette,
		'copyright': metadata.get('copyright'),
	})
	if db_album.discs.get(str(disc_number)) == null:
		db_album.discs.set(str(disc_number), {
			'tracks':[]},
		)
	var disc_size:int = db_album.discs[str(disc_number)].tracks.size()
	if track_number > disc_size:
		for _i:int in track_number-disc_size:
			db_album.discs[str(disc_number)].tracks.append(null)
	var track_data = {
		'title': track_title,
		'actual_artist': actual_artist,
		'length': duration,
		'lyrics': internal_lyrics,
		'channels': str(metadata.get('channels',-1)),
		'bit_rate': str(metadata.get('bitrate',-1)),
		'sample_rate': str(metadata.get('samplerate',-1)),
		'bpm': metadata.get('bpm'),
		'urls': metadata.get('urls'),
		'comment': metadata.get('comment'),
		'path': path,
		'last_modified': FileAccess.get_modified_time(path),
	}
	track_data.merge(custom_data, true)
	if track_number > 0:
		db_album.discs[str(disc_number)].tracks.set(track_number-1, track_data)
	else:
		db_album.discs[str(disc_number)].tracks.append(track_data)

	database.artists[artist].albums.set(album, db_album)
	database.track_count += 1
	database.library_size += FileAccess.get_size(path)
	#print('Indexed into DB: '+path)


static func reload_library(_callback:Callable) -> void:
	return
	#var root_dir := DirAccess.open(SessionManager.library_location)
	#if root_dir == null:
		#if callback && callback.is_valid(): callback.call(null)
		#return
	#ThreadHelper.create_thread((func() -> void:
		#FileUtils.walk_dir(SessionManager.library_location, func(path:String) -> void:
			#LibraryManager.rescan_track()
		#,Callable())
	#),callback)


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

	print('Loaded stream from: '+path)
	return audio_stream


#static func fetch_artist_cover(artist_name:String) -> ImageTexture:
	#'https://webservice.fanart.tv/{version}/{resource}/{id}?api_key='
	#'7e7651b46fca21ce80d7ac1863093b69'
