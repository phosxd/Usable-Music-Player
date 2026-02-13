class_name DBArtist extends RefCounted

## Artist name.
var name: String
## Whether or not the DB entry is valid.
## This may become false when the raw entry can no longer be found.
var valid := true


func _init(artist_name:String) -> void:
	name = artist_name


func _invalidate() -> void:
	valid = false


## Get specific album.
func get_album(album_name:String) -> DBAlbum:
	var raw_artist:Dictionary = LibraryManager.database.artists.get(name,{})
	var raw_album = raw_artist.get('albums',{}).get(album_name)
	if raw_album is not Dictionary:
		_invalidate()
		return

	return DBAlbum.new(self, album_name, raw_album)
