## Database item for music albums.
## Use [param new_or_reuse] when instantiating.
class_name DBAlbum extends RefCounted

enum DominantColorMethod {
	EASY,
	ACCURATE,
	ACCURATE_BLEND,
}

## Keeps track of unique [DBAlbum] objects. Will use existing object when instantiating when possible.
static var _objects:Dictionary[String,DBAlbum] = {}
static var default_cover := ImageTexture.create_from_image(preload('res://Assets/Icons/texture.svg').get_image())

## Parent artist.
var artist: DBArtist
## Album name.
var name: String
## Discs & the number of tracks in those discs.
var discs:Dictionary[String,int] = {
	'1': 0,
}
## Album cover image path. Use [param get_cover] to get a usable texture.
var cover_path: String
## Album release year. Not guaranteed to be formatted or be a valid year.
var year: String
## Album genre. No guaranteed to be formatted or be a valid genre.
var genre: String
var copyright: String
## Cached color palette for the album cover image.
var palette:Dictionary[String,Color] = {}
## Whether or not the DB entry is valid.
## This may become false when the raw entry can no longer be found.
var valid := true

var _cover: ImageTexture


## Same as [param new] method, except if this album has already been created before, just reuse an existing object.
static func new_or_reuse(db_artist:DBArtist, album_name:String, raw_info=null) -> DBAlbum:
	var old_object = _objects.get('%s:%s' % [db_artist.name, album_name], null)
	if old_object is DBAlbum:
		return old_object
	else:
		return DBAlbum.new(db_artist, album_name, raw_info)


## Construct new DBAlbum.
func _init(db_artist:DBArtist, album_name:String, raw_info=null) -> void:
	_objects.set('%s:%s' % [db_artist.name, album_name], self)
	artist = db_artist
	name = album_name
	if raw_info is not Dictionary:
		var raw_artist:Dictionary = LibraryManager.database.artists.get(artist.name,{})
		raw_info = raw_artist.get('albums',{}).get(album_name)
		if raw_info is not Dictionary:
			_invalidate()
			return

	var raw_discs = raw_info.get('discs',{})
	for disc in raw_discs:
		if disc is not String: continue
		var raw_disc = raw_discs[disc]
		if raw_disc is not Dictionary: continue
		var raw_tracks:Array = raw_disc.get('tracks',[])
		discs.set(disc, raw_tracks.size())

	var raw_cover_path = raw_info.get('cover')
	if raw_cover_path is String: cover_path = raw_cover_path

	var raw_palette = raw_info.get('palette')
	if raw_palette is Dictionary:
		palette = Dictionary(raw_palette, TYPE_STRING, '', null, TYPE_COLOR, '', null)
	else: palette = {}

	var raw_year = raw_info.get('year')
	if raw_year is String && not raw_year.is_empty():
		var raw_year_split:PackedStringArray = raw_year.split('T')
		year = raw_year_split[0]
	else: year = 'None found'

	var raw_genre = raw_info.get('genre')
	if raw_genre is String && not raw_genre.is_empty(): genre = raw_genre
	else: genre = 'None found'

	var raw_copyright = raw_info.get('copyright')
	if raw_copyright is String && not raw_copyright.is_empty(): copyright = raw_copyright
	else: copyright = 'None found'


func _invalidate() -> void:
	valid = false


## Returns an array of all tracks in order.
func get_all_tracks() -> Array[DBTrack]:
	var tracks:Array[DBTrack] = []
	for disc in discs:
		for i in discs[disc]:
			var track = get_track(i, int(disc))
			if track is not DBTrack: continue
			tracks.append(track)

	return tracks


## Get specific track from the [param track_number] & [param disc_number].
## Can return null if track cannot be found.
func get_track(track_number:int, disc_number:int=1) -> DBTrack:
	var raw_artist:Dictionary = LibraryManager.database.artists.get(artist.name,{})
	var raw_album:Dictionary = raw_artist.get('albums',{}).get(name,{})
	if raw_album is not Dictionary:
		_invalidate()
		return null

	var raw_discs:Dictionary = raw_album.get('discs',{})
	var raw_disc:Dictionary = raw_discs.get(str(disc_number),{'tracks':[]})
	var raw_track = raw_disc.tracks.get(track_number)
	if raw_track == null: return null

	var result = DBTrack.new_or_reuse(artist, self, track_number, disc_number, raw_track)
	if not result.valid: return null
	return result


## Returns the album cover [ImageTexture] or [code]null[/code] if it cannot be found.
func get_cover() -> ImageTexture:
	if _cover: return _cover
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


## Grabs the album dominant colors from cache.
## If the returned color is not accurate there may be no image available or the album may need to be rescanned.
func get_album_dominant_color() -> Color:
	#var primary:Color = palette.get('primary', Color.WHITE)
	#var secondary = palette.get('secondary', null)
	#var trinary = palette.get('trinary', null)
#
	#var result:Color = primary
	#if secondary is Color:
		#secondary.a = 0.5
		#result = result.blend(secondary)
	#if trinary is Color:
		#trinary.a = 0.25
		#result = result.blend(trinary)
	var blend_full:Color = palette.get('blend_full', Color.WHITE)
	return blend_full


static func calculate_colors(image_texture:ImageTexture) -> Dictionary[String,Color]:
	var result:Dictionary[String,Color] = {
		'blend_full': Color.WHITE,
		'primary': Color.WHITE,
		'secondary': Color.WHITE,
		'trinary': Color.WHITE,
		'last': Color.WHITE,
	}
	if image_texture == null: return result
	var image = image_texture.get_image()
	image.resize(12,12, Image.INTERPOLATE_BILINEAR)
	var image_size:Vector2i = image.get_size()

	# Iterate on each pixel & count the instances.
	var colors:Dictionary[Color,int] = {}
	for x in image_size.x:
		for y in image_size.y:
			var pixel:Color = image.get_pixel(x,y)
			if pixel.a != 1.0: continue # Exclude transparent pixels.
			# Exclude similar pixels.
			for color:Color in colors:
				if pixel.is_equal_approx(color): continue
			# Add color to count.
			colors.get_or_add(pixel, 0)
			colors[pixel] += 1

	var sorted:Array[int] = colors.values(); sorted.sort()
	# Return if no colors found.
	if sorted.is_empty(): return result

	var colors_2 := colors.duplicate()
	var sorted_reversed:Array[int] = sorted.duplicate(); sorted_reversed.reverse()
	for count:int in sorted_reversed:
		var blend_color:Color = colors_2.find_key(count)
		colors_2.erase(blend_color)
		blend_color.a = 0.3/count
		result.blend_full = result.blend_full.blend(blend_color)

	# Get primary color.
	result.primary = colors.find_key(sorted[-1])
	colors.erase(result.primary)
	sorted.remove_at(-1)
	# Get secondary color.
	if not sorted.is_empty():
		result.secondary = colors.find_key(sorted[-1])
		colors.erase(result.secondary)
		sorted.remove_at(-1)
	# Get trinary color.
	if not sorted.is_empty():
		result.trinary = colors.find_key(sorted[-1])
		colors.erase(result.trinary)
		sorted.remove_at(-1)
	# Get last color.
	if not sorted.is_empty():
		result.last = colors.find_key(sorted[0])
		colors.erase(result.last)
		sorted.remove_at(0)

	return result
