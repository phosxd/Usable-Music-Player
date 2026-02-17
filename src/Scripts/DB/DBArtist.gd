## Database item for music artists.
## Use [param new_or_reuse] when instantiating.
class_name DBArtist extends RefCounted

## Keeps track of unique [DBArtist] objects. Will use existing object when instantiating when possible.
static var _objects:Dictionary[String,DBArtist] = {}

## Artist name.
var name: String
var album_names: Array[String]
## Whether or not the DB entry is valid.
## This may become false when the raw entry can no longer be found.
var valid := true


## Same as [param new] method, except if this artist has already been created before, just reuse an existing object.
static func new_or_reuse(artist_name:String) -> DBArtist:
	var old_object = _objects.get(artist_name, null)
	if old_object is DBArtist:
		return old_object
	else:
		return DBArtist.new(artist_name)


func _init(artist_name:String) -> void:
	_objects.set(artist_name, self)
	name = artist_name
	var raw_artist:Dictionary = LibraryManager.database.artists.get(name,{'albums':{}})
	album_names = Array(raw_artist.albums.keys(), TYPE_STRING, '', null)
	if album_names.is_empty():
		_invalidate()


func _invalidate() -> void:
	valid = false


## Get specific album.
## Can return null if album cannot be found.
func get_album(album_name:String) -> DBAlbum:
	var raw_artist:Dictionary = LibraryManager.database.artists.get(name,{})
	var raw_album = raw_artist.get('albums',{}).get(album_name)
	if raw_album is not Dictionary:
		_invalidate()
		return null

	return DBAlbum.new(self, album_name, raw_album)
