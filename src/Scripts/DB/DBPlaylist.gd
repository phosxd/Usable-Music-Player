## Database item for music playlist.
class_name DBPlaylist extends RefCounted

signal saved
signal removed

static var default_cover := ImageTexture.create_from_image(preload('res://Themes/Normal/Assets/Icons/texture.svg').get_image())

## Playlist id.
var id:String = ''
## Track IDs in this playlist.
var track_ids: Array[String]
## Album cover image path. Use [param get_cover] to get a usable texture.
var cover_path:String = '':
	set(v):
		cover_path = v
		_cover = null
## Playlist date created.
var created_date:String = ''
## Playlist date last edited.
var last_edit_date:String = ''
## Cached color palette for the album cover image.
var palette:Dictionary[String,Color] = {}

## Whether or not the DB entry is valid.
var valid:bool = true
var changed:bool = false
var _cover


## Construct new DBAlbum.
func _init(data:Dictionary) -> void:
	update_data(data)


func update_data(data:Dictionary) -> void:
	id = data.get('id','')

	var raw_tracks = data.get('tracks',[])
	track_ids.clear(); track_ids.assign(raw_tracks)

	var raw_cover_path = data.get('cover_path')
	if raw_cover_path is String: cover_path = raw_cover_path

	var raw_palette = data.get('palette')
	if raw_palette is Dictionary:
		palette = Dictionary(raw_palette, TYPE_STRING, '', null, TYPE_COLOR, '', null)
	else: palette = {}


func save() -> void:
	var ajson = A2J.to_json(self, LibraryManager.a2j_ruleset)
	if ajson is not Dictionary:
		MiniLog.err('Failed to save playlist "%s".' % id, self)
		return
	var file := FileAccess.open(get_file_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(ajson))
	file.close()
	saved.emit()


static func add_from_data(data:Dictionary, add_track_ids:Array[String]=[]) -> DBPlaylist:
	var playlist_id:String = StringUtils.resolve_duplicate(data.get('name'), SessionManager.get_var('playlist_order'))
	var texture = data.get('texture')
	var playlist := DBPlaylist.new({
		'id': playlist_id,
		'tracks': add_track_ids,
		'cover_path': data.get('cover_path'),
		'palette': DBAlbum.calculate_colors(texture) if texture is Texture2D else {},
	})
	playlist.created_date = DBPlaylist.get_current_date()
	playlist.save()
	LibraryManager.playlists.append(playlist)
	SessionManager.get_var('playlist_order').append(playlist.id)
	return playlist


## Remove this playlist.
func remove() -> void:
	valid = false
	LibraryManager.playlists.erase(self)
	var err:Error = DirAccess.remove_absolute(get_file_path())
	if err != OK:
		MiniLog.warn('Failed to remove playlist file at $~%s~$.' % get_file_path(), self)

	removed.emit()


func get_file_path() -> String:
	return LibraryManager.playlists_path+id+'.json'


## Returns all [DBTrack] objects in the playlist in order.
func get_tracks() -> Array[DBTrack]:
	var tracks: Array[DBTrack]
	for track_id:String in track_ids:
		tracks.append(DBTrack.from_id(track_id))
	return tracks


## Returns the playlist cover [ImageTexture] or [code]null[/code] if it cannot be found.
func get_cover() -> ImageTexture:
	if _cover: return _cover
	var cover
	if FileAccess.file_exists(cover_path):
		var image = Image.load_from_file(cover_path)
		if image is Image:
			ImageUtils.limit_size(image, Vector2.ONE*SessionManager.get_var('image_detail'))
			image.generate_mipmaps()
			cover = ImageTexture.create_from_image(image)
	if not cover: return null

	# Save cover in memory for faster reloading.
	self._cover = cover
	return cover


## Calls [param get_cover] in a separate thread then calls [param callback] with the result.
func get_cover_threaded(callback:Callable) -> void:
	if _cover:
		callback.call(_cover)
		return
	Async.create_thread(get_cover, callback)


## Grabs the cover dominant colors from [member] pallete.
func get_cover_dominant_color() -> Color:
	var blend_full:Color = palette.get('blend_full', Color.WHITE)
	return blend_full


## Gets the current date. Use the result from this to set a properly formatted date in [member created_date] or [member last_edit_date].
static func get_current_date() -> String:
	return Time.get_datetime_string_from_system().split('T')[0]
