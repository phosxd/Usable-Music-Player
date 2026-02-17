## Database item for music tracks.
## Use [param new_or_reuse] when instantiating.
class_name DBTrack extends RefCounted

## Keeps track of unique [DBTrack] objects. Will use existing object when instantiating when possible.
static var _objects:Dictionary[String,DBTrack] = {}

## Parent artist.
var artist: DBArtist
## Parent album.
var album: DBAlbum
## Track name.
var name: String
## Track number.
var number: int
## Track length.
var length: float
## Track absolute file path.
var path: String
## Whether or not the DB entry is valid.
## This may become false when the raw entry can no longer be found.
var valid := true


## Same as [param new] method, except if this track has already been created before, just reuse an existing object.
static func new_or_reuse(db_artist:DBArtist, db_album:DBAlbum, track_number:int, raw_info=null) -> DBTrack:
	var old_object = _objects.get('%s:%s:%s' % [db_artist.name, db_album.name, track_number], null)
	if old_object is DBTrack:
		return old_object
	else:
		return DBTrack.new(db_artist, db_album, track_number, raw_info)


static func update(db_artist:DBArtist, db_album:DBAlbum, track_number:int, raw_info=null) -> void:
	var object = _objects.get('%s:%s:%s' % [db_artist.name, db_album.name, track_number], null)
	if not object: return
	object = object as DBTrack

	if raw_info is not Dictionary:
		var raw_artist:Dictionary = LibraryManager.database.artists.get(db_artist.name,{'albums':{}})
		var raw_album:Dictionary = raw_artist.albums.get(db_album.name,{'tracks':[]})
		raw_info = raw_album.tracks.get(track_number)
		if raw_info is not Dictionary: raw_info = {}

	var raw_title = raw_info.get('title')
	if raw_title is String && not raw_title.is_empty(): object.name = raw_title
	else: object.name = 'No title found'

	var raw_length = raw_info.get('length')
	if raw_length is float: object.length = raw_length
	else: object.length = 0

	var raw_path = raw_info.get('path')
	if raw_path is String && not raw_path.is_empty(): object.path = raw_path
	else: object.path = ''

	if object.path.is_empty() or object.length < 0:
		object._invalidate()


## Construct new DBTrack.
## Do not use [param raw_info].
func _init(db_artist:DBArtist, db_album:DBAlbum, track_number:int, raw_info=null) -> void:
	_objects.set('%s:%s:%s' % [db_artist.name, db_album.name, track_number], self)
	artist = db_artist
	album = db_album
	number = track_number
	update(artist, album, number, raw_info)


func _invalidate() -> void:
	valid = false


func get_stream() -> AudioStream:
	return LibraryManager.load_audio(path)


static func get_track_position_formatted(value:float) -> String:
	var remainder := int(fmod(value,60))
	return '%s:%s' % [int(value/60), ('0' if remainder < 10 else '') + str(remainder)]
