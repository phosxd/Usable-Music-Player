class_name DBTrack extends RefCounted

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


## Construct new DBTrack.
## Do not use [param raw_info].
func _init(db_artist:DBArtist, db_album:DBAlbum, track_number:int, raw_info=null) -> void:
	artist = db_artist
	album = db_album
	number = track_number
	if raw_info is not Dictionary:
		var raw_artist:Dictionary = LibraryManager.database.artists.get(artist.name,{})
		var raw_album:Dictionary = raw_artist.albums.get(album.name,{})
		raw_info = raw_album.tracks.get(track_number)
		if raw_info is not Dictionary: raw_info = {}

	var raw_title = raw_info.get('title')
	if raw_title is String && not raw_title.is_empty(): name = raw_title
	else: name = 'No title found'

	var raw_length = raw_info.get('length')
	if raw_length is float: length = raw_length
	else: length = 0

	var raw_path = raw_info.get('path')
	if raw_path is String && not raw_path.is_empty(): path = raw_path
	else: path = ''

	if path.is_empty() or length < 0:
		_invalidate()


func _invalidate() -> void:
	valid = false
