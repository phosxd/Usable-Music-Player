## Music library interface & container.
class_name DBLibrary extends Object

signal scan_progress_changed(progress:int)
signal scan_finished
signal scan_started

const minilog_importance := MiniLog.Importance.High

enum LibraryType {
	LocalDirectory,
}

enum ArtistSortMode {
	## Sort by title in alphabetical order.
	title,
}

enum AlbumSortMode {
	## Sort by title in alphabetical order.
	title,
	## Sort by artist title in alphabetical order.
	artist,
	## Sort by year released.
	year,
}

enum TrackSortMode {
	## Sort by title in alphabetical order.
	title,
	## Sort by album title in alphabetical order.
	album,
	## Sort by artist title in alphabetical order.
	artist,
	## Sort by year released.
	year,
	## Sort by track number.
	number,
	## Sort by track length.
	length,
}

var type := LibraryType.LocalDirectory
var id: String
var name: String:
	set(value):
		name = value
		changed = true
var path: String:
	set(value):
		path = value
		changed = true
var hidden:bool = false:
	set(value):
		hidden = value
		changed = true
## All artists.
var artists:Array[DBArtist] = []
## All albums.
var albums:Array[DBAlbum] = []
## All tracks.
var tracks:Array[DBTrack] = []

var changed:bool = false
var currently_updating:bool = false
var valid:bool = true


static func _generate_id() -> String:
	var result:String = ''
	for i in 6:
		result += str(randi_range(0,9))

	# Try again if ID taken.
	for library:DBLibrary in LibraryManager.libraries:
		if library.internal_id == result:
			return _generate_id()

	return result


func save() -> void:
	var ajson = A2J.to_json(self, LibraryManager.a2j_ruleset)
	if ajson is not Dictionary:
		MiniLog.err('Failed to save library "%s".' % self.id, self)
		return
	var file := FileAccess.open(self.get_file_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(ajson))
	file.close()


func remove() -> void:
	self.valid = false
	LibraryManager.libraries.erase(self)
	var err:Error = DirAccess.remove_absolute(self.get_file_path())
	print(self.get_file_path())
	print(error_string(err))


func refresh(auto:bool=false) -> void:
	if self.currently_updating:
		if not auto: MiniLog.warn('Cannot start scan for $~%s~$, already in progress.' % self.id, DBLibrary)
		return
	if not DirAccess.dir_exists_absolute(path):
		if not auto: MiniLog.err('Library path "%s" is invalid. Skipping scan.' % path, DBLibrary)
		return
	for library:DBLibrary in LibraryManager.libraries:
		if library.currently_updating:
			if not auto: MiniLog.warn('Cannot start scan for $~%s~$, another library is currently scanning.' % self.id, DBLibrary)
			return

	self.currently_updating = true
	self.scan_started.emit()
	if not auto: MiniLog.info('Starting scan for $~%s~$.' % self.id, DBLibrary)

	Async.create_thread(self._refresh, func(made_changes:bool) -> void:
		self.currently_updating = false
		self.scan_finished.emit()
		if made_changes:
			self.changed = true
			SessionManager.main_scene.refresh_tab()
		if not auto: MiniLog.info('Finished scan for $~%s$~.' % self.id, DBLibrary)
		self.save()
	)


func _refresh() -> bool:
	var made_changes:Array[bool] = [false]

	# Get last modified time for all tracks.
	var last_modified_times:Dictionary[String,int] = {}
	for track:DBTrack in self.tracks:
		last_modified_times.set(track.path, track.last_modified_time)

	# Scan files in the library.
	var parsed_images:Array[String] = []
	var found_paths:Array[String] = []
	var progress:Array[int] = [0]
	FileUtils.walk_dir(self.path, func(file_path:String) -> void:
		if not self.valid: return
		if file_path.get_extension().to_lower() not in LibraryManager.valid_audio_extensions: return
		var short_file_path:String = file_path.trim_prefix(self.path).trim_prefix('/')
		found_paths.append(short_file_path)
		var lmt:int = FileAccess.get_modified_time(file_path)
		var track_lmt = last_modified_times.get(short_file_path,null)
		# Don't scan if file has not changed.
		if track_lmt is int && lmt == track_lmt: return
		# Scan file.
		made_changes[0] = true
		var entries:Array = Metadata.get_audio_meta([file_path], LibraryManager.image_cache_path)
		for entry:Dictionary in entries:
			if entry.is_empty():
				MiniLog.err('Failed to scan file "%s".' % short_file_path, self)
				continue
			_parse_entry(file_path, short_file_path, entry, parsed_images)
			progress[0] += 1
			self.scan_progress_changed.emit.call_deferred(progress[0])
	,null, true)

	parsed_images.clear()

	# Remove tracks that have been removed from the library.
	for track:DBTrack in self.tracks.duplicate():
		if track.path not in found_paths:
			track.remove()
			made_changes[0] = true

	return made_changes[0]


func _parse_entry(full_track_path:String, track_path:String, entry:Dictionary, parsed_images:Array[String]) -> void:
	if track_path.is_empty(): return
	var file_size:int = entry.get('filesize',null)
	if not file_size: file_size = FileAccess.get_size(full_track_path)

	var artist_name:String = entry.get('artist','').replace('\n','')
	var actual_artist:String = artist_name
	var album_artist:String = entry.get('albumartist','').replace('\n','')
	if not album_artist.is_empty(): artist_name = album_artist

	var palette = {}
	var cover_path:String = entry.get('cover_path','')
	if not cover_path.is_empty() && cover_path not in parsed_images && FileAccess.file_exists(cover_path):
		var image = Image.load_from_file(cover_path)
		image = ImageTexture.create_from_image(image)
		palette = DBAlbum.calculate_colors(image)
		parsed_images.append(cover_path)

	var track_name:String = entry.get('title','').replace('\n','')
	var track_number:int = int(entry.get('track',0))
	var disc_number:int = int(entry.get('disc',1))

	if track_name.is_empty(): track_name = track_path
	if disc_number == 0: disc_number = 1

	# Sort data.
	var artist_data:Dictionary = {
		'name': artist_name,
		'albums': [],
	}
	@warning_ignore('incompatible_ternary')
	var album_data:Dictionary = {
		'name': entry.get('album','').replace('\n',''),
		'year': entry.get('year','').replace('\n',''),
		'genres': PackedStringArray(entry.get('genres',[])),
		'cover_path': cover_path,
		'tracks': [],
		'palette': palette,
		'copyright': entry.get('copyright'),
		'replay_gain': entry.get('replaygain_album',0.0),
	}
	var track_data = {
		'path': track_path,
		'name': track_name,
		'actual_artist': actual_artist,
		'number': track_number,
		'disc': disc_number,
		'length': entry.get('duration',0),
		'channels': str(entry.get('channels',-1)),
		'bit_rate': str(entry.get('bitrate',-1)),
		'sample_rate': str(entry.get('samplerate',-1)),
		'bpm': entry.get('bpm'),
		'replay_gain': entry.get('replaygain_track',0.0),
		'comment': entry.get('comment'),
		'last_modified_time': FileAccess.get_modified_time(full_track_path),
		'file_size': file_size,
	}

	# Add to library.
	var artist_entry: DBArtist
	var album_entry: DBAlbum
	var track_entry: DBTrack
	# Find or create artist.
	for artist:DBArtist in self.artists:
		if artist.name == artist_data.name:
			artist_entry = artist
			break
	if not artist_entry: artist_entry = DBArtist.new(self, artist_data)
	# Find or create album.
	for album:DBAlbum in self.albums:
		if album.artist == artist_entry \
		&& album.name == album_data.name \
		&& album.year == album_data.year:
			album_entry = album
			break
	if not album_entry: album_entry = DBAlbum.new(artist_entry, album_data)
	# Find or create track.
	for track:DBTrack in self.tracks:
		if track.album == album_entry \
		&& track.name == track_data.name \
		&& track.path == track_data.path \
		&& track.number == track_data.number:
			track_entry = track
			break
	if not track_entry: track_entry = DBTrack.new(album_entry, track_data)
	else:
		track_entry.update_data(track_data)
	track_entry.save_lyrics(entry.get('lyrics',''))
	#MiniLog.pro('Scanned "$~%s~$".' % track_path.trim_prefix(library.path), LibraryManager)


func get_file_path() -> String:
	return LibraryManager.libraries_path+self.id+'.json'


## Returns a list of [DBArtist], [DBAlbum], or [DBTrack] (depending on [param item_type]) that have the specified [param name].
func get_item_by_name(item_type, expected_name:String, case_sensitive:bool=true) -> Array:
	var list: Array
	match item_type:
		DBArtist: list = artists
		DBAlbum: list = albums
		DBTrack: list = tracks

	if not case_sensitive: expected_name = expected_name.to_lower()
	list = list.filter(func(item) -> bool:
		var item_name = item.get('name')
		if item_name is String:
			if not case_sensitive: item_name = item_name.to_lower()
			return item_name == expected_name
		return false
	)

	return list


## Returns a list of [DBArtist], [DBAlbum], or [DBTrack] (depending on [param item_type]) that have the specified [param value].
func get_item_by_property(item_type, property:String, value:Variant) -> Array:
	var list: Array
	match item_type:
		DBArtist: list = artists
		DBAlbum: list = albums
		DBTrack: list = tracks

	list = list.filter(func(item) -> bool:
		var item_value = item.get(property)
		if item_value == null: return false
		return item_value == value
	)

	return list


## Returns a list of [DBArtist] sorted using [param sort_mode].
func get_artists_sorted(sort_mode:=ArtistSortMode.title) -> Array[DBArtist]:
	var result:Array[DBArtist] = []; result.assign(self.artists)
	match sort_mode:
		ArtistSortMode.title:
			result.sort_custom(func(a:DBArtist, b:DBArtist) -> bool:
				return a.name.to_lower() < b.name.to_lower()
			)

	return result


## Returns a list of [DBAlbum] sorted using [param sort_mode].
func get_albums_sorted(sort_mode:=AlbumSortMode.title) -> Array[DBAlbum]:
	var result:Array[DBAlbum] = []; result.assign(self.albums)
	match sort_mode:
		AlbumSortMode.title:
			result.sort_custom(func(a:DBAlbum, b:DBAlbum) -> bool:
				if not a or not b: return false
				return a.name.to_lower() < b.name.to_lower()
			)
		AlbumSortMode.artist:
			result.sort_custom(func(a:DBAlbum, b:DBAlbum) -> bool:
				if not a or not b: return false
				return a.artist.name.to_lower() < b.artist.name.to_lower()
			)
		AlbumSortMode.year:
			result.sort_custom(func(a:DBAlbum, b:DBAlbum) -> bool:
				if not a or not b: return false
				return a.year.to_int() < b.year.to_int()
			)

	return result


## Returns a list of [DBTrack] sorted using [param sort_mode].
func get_tracks_sorted(sort_mode:=TrackSortMode.title) -> Array[DBTrack]:
	var result:Array[DBTrack] = []; result.assign(self.tracks)
	match sort_mode:
		TrackSortMode.title:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				if not a or not b: return false
				return a.name < b.name
			)
		TrackSortMode.album:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				if not a or not b: return false
				return a.album.name < b.album.name
			)
		TrackSortMode.artist:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				if not a or not b: return false
				return a.album.artist.name < b.album.artist.name
			)
		TrackSortMode.year:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				if not a or not b: return false
				return a.album.year.to_int() < b.album.year.to_int()
			)
		TrackSortMode.number:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				if not a or not b: return false
				return a.number < b.number
			)
		TrackSortMode.length:
			result.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
				if not a or not b: return false
				return a.length < b.length
			)

	return result


## Returns a dictionary of [DBAlbum] objects with the genre as the key.
func get_genres_sorted() -> Dictionary[String,Array]:
	var result:Dictionary[String,Array] = {}
	for album:DBAlbum in albums:
		for genre in album.genres:
			result.get_or_add(genre, [])
			result[genre].append(album)

	return result
