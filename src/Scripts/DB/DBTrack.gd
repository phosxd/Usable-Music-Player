## Database item for music tracks.
## Use [param new_or_reuse] when instantiating.
class_name DBTrack extends RefCounted

## Keeps track of unique [DBTrack] objects. Will use existing object when instantiating when possible.
static var _objects:Dictionary[String,DBTrack] = {}

## Raw track data.
var raw: Dictionary
## Parent artist.
var artist: DBArtist
## Parent album.
var album: DBAlbum
## Track name.
var name: String
## Track actual artist name.
var actual_artist: String
## Track number.
var number: int
## Track album disc number.
var disc: int
## Track length.
var length: float
## Track absolute file path.
var path: String
## Track built-in lyrics.
var internal_lyrics: String
## Whether or not the DB entry is valid.
## This may become false when the raw entry can no longer be found.
var valid := true


## Same as [param new] method, except if this track has already been created before, just reuse an existing object.
static func new_or_reuse(db_artist:DBArtist, db_album:DBAlbum, track_number:int, disc_number:int=1, raw_info=null) -> DBTrack:
	var old_object = _objects.get('%s:%s:%s:%s' % [db_artist.name, db_album.name, disc_number, track_number], null)
	if old_object is DBTrack && old_object.valid:
		return old_object
	else:
		return DBTrack.new(db_artist, db_album, track_number, disc_number, raw_info)


## Construct new DBTrack.
## Do not use [param raw_info].
func _init(db_artist:DBArtist, db_album:DBAlbum, track_number:int, disc_number:int=1, raw_info=null) -> void:
	_objects.set('%s:%s:%s:%s' % [db_artist.name, db_album.name, disc_number, track_number], self)
	artist = db_artist
	album = db_album
	number = track_number
	disc = disc_number
	var object = _objects.get('%s:%s:%s:%s' % [db_artist.name, db_album.name, disc_number, track_number], null)
	if not object: return
	object = object as DBTrack

	if raw_info is not Dictionary:
		var raw_artist:Dictionary = LibraryManager.database.artists.get(db_artist.name,{'albums':{}})
		var raw_album:Dictionary = raw_artist.albums.get(db_album.name,{'discs':{}})
		var raw_disc:Dictionary = raw_album.discs.get(str(disc_number),{'tracks':[]})
		if track_number < raw_disc.tracks.size():
			raw_info = raw_disc.tracks.get(track_number)
		if raw_info is not Dictionary: return

	object.raw = raw_info

	var raw_path = raw_info.get('path')
	if raw_path is String && not raw_path.is_empty(): object.path = raw_path
	else: object.path = ''

	if object.path.is_empty() or object.length < 0:
		object._invalidate()

	var raw_length = raw_info.get('length')
	if raw_length is float: object.length = raw_length
	else: object.length = 0

	var raw_title = raw_info.get('title')
	if raw_title is String && not raw_title.is_empty(): object.name = raw_title
	else: object.name = 'No title found'

	var raw_aa = raw_info.get('actual_artist')
	if raw_aa is String && not raw_aa.is_empty(): object.actual_artist = raw_aa
	else: object.actual_artist = db_artist.name

	var raw_lyrics = raw_info.get('lyrics')
	if raw_lyrics is String && not raw_lyrics.is_empty(): object.internal_lyrics = raw_lyrics


func _invalidate() -> void:
	valid = false


func get_stream() -> AudioStream:
	return LibraryManager.load_audio(path)


## Returns file system firendly name of the track.
func as_filename() -> String:
	return '%s__%s__%s__%s' % [artist.name.replace('/','_'), album.name.replace('/','_'), disc, number]


## Returns any stored lyrics for this track, or an empty string if none found.
func get_lyrics() -> String:
	if internal_lyrics && not internal_lyrics.is_empty(): return internal_lyrics
	var text = FileAccess.get_file_as_string(get_lyrics_path())
	return text


## Returns the path to the file storing this track's lyrics.
func get_lyrics_path() -> String:
	return LibraryManager.lyrics_path+'/'+as_filename()+'.txt'


func save_lyrics(lyrics:String) -> void:
	DirAccess.make_dir_recursive_absolute(LibraryManager.lyrics_path)
	var file := FileAccess.open(get_lyrics_path(), FileAccess.WRITE)
	file.store_string(lyrics)
	file.close()


static func get_track_position_formatted(value:float) -> String:
	var remainder := int(fmod(value,60))
	return '%s:%s' % [int(value/60), ('0' if remainder < 10 else '') + str(remainder)]
