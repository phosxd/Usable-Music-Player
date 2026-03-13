## Database item for music artists.
## Use [param new_or_reuse] when instantiating.
class_name DBArtist extends RefCounted

## Artist name.
var name: String
## All albums in this artist.
var albums: Dictionary[String,DBAlbum]
## Whether or not the DB entry is valid.
var valid := true
var _cover


func _init(name_:String, data:Dictionary) -> void:
	if name_ == '.dummy': return # Don't do any processing if is a dummy.
	name = name_
	var albums_ = data.get('albums',{})
	for album_name:String in albums_:
		albums.set(album_name, albums_[album_name])
	if albums.is_empty():
		remove()

	LibraryManager.database.artists.set(name, self)


## Remove this artist & all tracks & albums under this artist.
func remove() -> void:
	LibraryManager.remove_artist(name)


## Returns file system firendly name of the track.
func as_filename() -> String:
	return '%s' % [name.replace('/','_')]


func get_all_tracks() -> Array[DBTrack]:
	var result:Array[DBTrack] = []
	for album:DBAlbum in albums.values():
		result.append_array(album.get_all_tracks())

	return result


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
	Async.create_thread(get_cover, callback)


func save_cover(cover:Image) -> void:
	var cover_path = get_cover_path()
	if cover_path.is_empty(): return
	DirAccess.make_dir_recursive_absolute(LibraryManager.artist_image_cache)
	if cover:
		cover.save_png(cover_path)
	else:
		var dummy_cover = Image.create_empty(1,1, false, Image.FORMAT_RGBA8)
		dummy_cover.save_png(cover_path)
