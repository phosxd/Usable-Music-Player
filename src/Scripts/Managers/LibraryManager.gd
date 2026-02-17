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
	## Sort by length.
	LENGTH,
}

const valid_audio_extensions:Array[String] = ['wav','ogg','mp3','mpga']
const db_cache_path:String = 'user://database.dat'


static var database:Dictionary = {
	'location': '',
	'library_size': 0,
	'library_track_count': 0,
	'artists': {
		'Example Artist': {
			'cover': null,
			'albums': {
				'Example Album': {
					'year': '2026',
					'genre': 'Rock',
					'tracks': [ # Sorted by track number, missing tracks will be present as null to preserve order of other tracks.
						{
							'title': 'Example Track',
							'length': 65,
							'path': 'full/path/to/audio/file.wav',
							'last_accessed': '',
						},
					],
					'cover': null,
				},
			},
		},
	},
}

## Database cache size in compressed bytes.
static var db_cache_size_compressed:int =0
## Database cache size in bytes.
static var db_cache_size:int = 0


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
				return a.ablum.name < b.ablum.name
			)
		TrackSortMode.ARTIST:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.album.artist.name < b.album.artist.name
			)
		TrackSortMode.YEAR:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.ablum.year.to_int() < b.album.year.to_int()
			)
		TrackSortMode.GENRE:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.ablum.genre < b.album.genre
			)
		TrackSortMode.NUMBER:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.number > b.number
			)
		TrackSortMode.LENGTH:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				return a.length < b.length
			)

	return result


## Rescans the track & updates the database accordingly.
## Returns the updated DBTrack.
static func rescan_track(track:DBTrack) -> DBTrack:
	database.artists[track.artist.name].albums[track.album.name].tracks.set(track.number, null)
	database.library_track_count -= 1
	var track_size = FileAccess.get_size(track.path)
	if track_size > 0: database.library_size -= track_size
	index_file(track.path, track.number)
	save_database()

	DBTrack.update(track.artist, track.album, track.number)
	return DBTrack.new_or_reuse(track.artist, track.album, track.number)


static func wipe_database() -> void:
	database.set('artists', {})
	database.set('library_size', 0)
	database.set('library_track_count', 0)
	database.erase('timestamp')


static func save_database() -> void:
	var file := FileAccess.open_compressed(db_cache_path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if file == null:
		printerr('Failed to save database.')
		return
	var bytes := var_to_bytes_with_objects(database)
	db_cache_size = bytes.size()
	file.store_buffer(bytes)
	file.close()
	db_cache_size_compressed = FileAccess.get_size(db_cache_path)


static func load_library_from_cache() -> void:
	var file := FileAccess.open_compressed(db_cache_path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if file == null: return
	var bytes := file.get_buffer(file.get_length())
	db_cache_size = bytes.size()
	file.close()
	db_cache_size_compressed = FileAccess.get_size(db_cache_path)

	var result = bytes_to_var_with_objects(bytes)
	if result is Dictionary:
		database = result


static func load_library(root_path:String) -> void:
	LibraryManager.wipe_database()
	database.location = root_path
	database.set('timestamp', Time.get_datetime_string_from_system(true, true))
	_load_library(root_path)
	save_database()


static func _load_library(root_path:String) -> void:
	var root_dir := DirAccess.open(root_path)
	if root_dir == null: return
	root_dir.list_dir_begin()
	while true:
		var path:String = root_dir.get_next()
		if path.is_empty(): break
		if root_dir.current_is_dir():
			LibraryManager._load_library(root_path+'/'+path)
		else:
			LibraryManager.index_file(root_path+'/'+path)
	root_dir.list_dir_end()


static func index_file(path:String, track_number_override:int=-1) -> void:
	var extension:String = path.split('.')[-1].to_lower()
	if extension not in LibraryManager.valid_audio_extensions: return
	# Load audio file.
	var audio_stream = load_audio(path)
	if audio_stream is not AudioStream: return
	audio_stream = audio_stream as AudioStream
	# Grab metadata.
	var metadata:MusicMetadata = MusicMetadata.new(audio_stream)
	var artist:String = metadata.get_most_relevent_artist().replace('\n','')
	var album:String = metadata.album.replace('\n','')
	var cover:ImageTexture = metadata.get_most_relevent_cover()
	var track_title:String = metadata.title.replace('\n','')
	var track_number:int = metadata.track_no
	if track_title.is_empty(): track_title = path.split('/')[-1].split('.')[0]
	# Add to database.
	var db_artist:Dictionary = database.artists.get_or_add(artist, {
		#'cover': fetch_artist_cover(artist),
		'albums': {},
	})
	@warning_ignore('incompatible_ternary')
	var db_album:Dictionary = db_artist.albums.get_or_add(album, {
		'year': str(metadata.year) if metadata.year > 10 else null,
		'genre': metadata.genre if not metadata.genre.is_empty() else null,
		'cover': cover,
		'tracks': [],
		'palette': DBAlbum.calculate_colors(cover),
	})
	if track_number > db_album.tracks.size(): db_album.tracks.resize(track_number)
	var track_data = {
		'title': track_title,
		'length': audio_stream.get_length(),
		'channels': str(metadata.get_tag('channels',-1)),
		'bit_rate': str(metadata.get_tag('bitrate',-1)),
		'sample_rate': str(metadata.get_tag('sample_rate',-1)),
		'bpm': metadata.bpm,
		'copyright': metadata.copyright,
		'urls': metadata.urls,
		'comments': metadata.comments,
		'path': path,
		'last_accessed': FileAccess.get_access_time(path),
	}
	if track_number_override != -1:
		db_album.tracks.set(track_number_override, track_data)
	elif track_number == -1:
		db_album.tracks.append(track_data)
	else:
		db_album.tracks.set(track_number-1, track_data)

	database.library_size += FileAccess.get_size(path)
	database.library_track_count += 1


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

	return audio_stream


#static func fetch_artist_cover(artist_name:String) -> ImageTexture:
	#'https://webservice.fanart.tv/{version}/{resource}/{id}?api_key='
	#'7e7651b46fca21ce80d7ac1863093b69'
