class_name DBAlbum extends RefCounted

var default_cover := ImageTexture.create_from_image(preload('res://Assets/Icons/texture.svg').get_image())

## Parent artist.
var artist: DBArtist
## Album name.
var name: String
## Number of tracks in the album.
var track_count: int
## Album cover image.
var cover: ImageTexture
## Album release year. Not guaranteed to be formatted or be a valid year.
var year: String
## Album genre. No guaranteed to be formatted or be a valid genre.
var genre: String
## Whether or not the DB entry is valid.
## This may become false when the raw entry can no longer be found.
var valid := true


## Construct new DBAlbum.
## Do not use [param raw_info].
func _init(db_artist:DBArtist, album_name:String, raw_info=null) -> void:
	artist = db_artist
	name = album_name
	if raw_info is not Dictionary:
		var raw_artist:Dictionary = LibraryManager.database.artists.get(artist.name,{})
		raw_info = raw_artist.get('albums',{}).get(album_name)
		if raw_info is not Dictionary:
			_invalidate()
			return

	track_count = raw_info.get('tracks',[]).size()

	var raw_cover = raw_info.get('cover')
	if raw_cover is ImageTexture: cover = raw_cover
	else: cover = default_cover

	var raw_year = raw_info.get('year')
	if raw_year is String && not raw_year.is_empty(): year = raw_year
	else: year = 'No year found'

	var raw_genre = raw_info.get('genre')
	if raw_genre is String && not raw_genre.is_empty(): genre = raw_genre
	else: genre = 'No genre found'


func _invalidate() -> void:
	valid = false


## Get specific track from the [param track_number].
func get_track(track_number:int) -> void:
	var raw_artist:Dictionary = LibraryManager.database.artists.get(artist.name,{})
	var raw_album:Dictionary = raw_artist.get('albums',{}).get(name,{})
	var raw_track = raw_album.get('tracks',[]).get(track_number)
	if raw_album is not Dictionary:
		_invalidate()
		return

	return DBTrack.new(artist, self, track_number, raw_track)
