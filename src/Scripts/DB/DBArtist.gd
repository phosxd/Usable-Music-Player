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
var _cover


## Same as [param new] method, except if this artist has already been created before, just reuse an existing object.
static func new_or_reuse(artist_name:String) -> DBArtist:
	var old_object = _objects.get(artist_name, null)
	if old_object is DBArtist:
		return old_object
	else:
		return DBArtist.new(artist_name)


func _init(artist_name:String) -> void:
	_objects.set(artist_name, self)
	_cover = null
	name = artist_name
	var raw_artist:Dictionary = LibraryManager.database.artists.get(name,{'albums':{}})
	album_names = Array(raw_artist.albums.keys(), TYPE_STRING, '', null)
	if album_names.is_empty():
		_invalidate()


func _invalidate() -> void:
	valid = false


## Returns file system firendly name of the track.
func as_filename() -> String:
	return '%s' % [name.replace('/','_')]


## Get specific album.
## Can return null if album cannot be found.
func get_album(album_name:String) -> DBAlbum:
	var raw_artist:Dictionary = LibraryManager.database.artists.get(name,{})
	var raw_album = raw_artist.get('albums',{}).get(album_name)
	if raw_album is not Dictionary:
		_invalidate()
		return null

	return DBAlbum.new_or_reuse(self, album_name, raw_album)


## Returns the path to the artist's cover image.
func get_cover_path() -> String:
	return LibraryManager.artist_image_cache+'/'+as_filename()+'.png'


## Returns the cover [ImageTexture] or [code]null[/code] if it cannot be found.
func get_cover() -> ImageTexture:
	if _cover: return _cover
	var cover_path:String = get_cover_path()
	var cover
	if FileAccess.file_exists(cover_path):
		var image = Image.load_from_file(cover_path)
		if image is Image:
			cover = ImageTexture.create_from_image(image)
	if not cover: return null
	_cover = cover
	return cover


## Calls [param get_cover] in a separate thread then calls [param callback] with the result.
func get_cover_threaded(callback:Callable) -> void:
	if _cover:
		callback.call(_cover)
		return
	ThreadHelper.create_thread(get_cover, callback)


func save_cover(cover:Image) -> void:
	var cover_path = get_cover_path()
	if cover_path.is_empty(): return
	DirAccess.make_dir_recursive_absolute(LibraryManager.artist_image_cache)
	if cover:
		cover.save_png(cover_path)
	else:
		var dummy_cover = Image.create_empty(1,1, false, Image.FORMAT_RGBA8)
		dummy_cover.save_png(cover_path)
