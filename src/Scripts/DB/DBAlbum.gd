## Database item for music albums.
## Use [param new_or_reuse] when instantiating.
class_name DBAlbum extends RefCounted

enum DominantColorMethod {
	EASY,
	ACCURATE,
	ACCURATE_BLEND,
}
const album_cover_size_1 := Vector2i(250,250)
const album_cover_size_2 := Vector2i(500,500)
const album_cover_size_3 := Vector2i(1000,1000)

static var default_cover := ImageTexture.create_from_image(preload('res://Themes/Normal/Assets/Icons/texture.svg').get_image())

## Parent artist.
var artist: DBArtist
## Album name.
var name:String = ''
## Tracks in this album.
var tracks: Array[DBTrack]
## Album cover image path. Use [param get_cover] to get a usable texture.
var cover_path:String = ''
## Album release year. Not guaranteed to be formatted or be a valid year.
var year:String = ''
## Album genres. Not guaranteed to be formatted or be a valid genre.
var genres := PackedStringArray()
## Album copyright. Not Not guaranteed to be formatted.
var copyright:String = ''
## Cached color palette for the album cover image.
var palette:Dictionary[String,Color] = {}

## Whether or not the DB entry is valid.
var valid := true
var _cover


## Construct new DBAlbum.
func _init(artist_:DBArtist, data:Dictionary) -> void:
	if artist_ == null: return # Don't do any processing if is a dummy.
	artist = artist_
	artist.albums.append(self)
	artist.library.albums.append(self)
	update_data(data)


func update_data(data:Dictionary) -> void:
	name = data.get('name','')

	var raw_tracks = data.get('tracks',[])
	tracks.clear(); tracks.assign(raw_tracks)

	var raw_cover_path = data.get('cover_path')
	if raw_cover_path is String: cover_path = raw_cover_path

	var raw_palette = data.get('palette')
	if raw_palette is Dictionary:
		palette = Dictionary(raw_palette, TYPE_STRING, '', null, TYPE_COLOR, '', null)
	else: palette = {}

	var raw_year = data.get('year')
	if raw_year is String && not raw_year.is_empty():
		var raw_year_split:PackedStringArray = raw_year.split('T')
		year = raw_year_split[0]
	else: year = ''

	var raw_genres = data.get('genres')
	genres = raw_genres
	#if raw_genre is String && not raw_genre.is_empty():
		#raw_genre = raw_genre \
			#.replace(' / ','&&') \
			#.replace('/ ','&&') \
			#.replace('/','&&') \
			#.replace(' ; ','&&') \
			#.replace('; ','&&') \
			#.replace(';','&&') \
			#.replace(' , ','&&') \
			#.replace(', ','&&') \
			#.replace(',','&&')
		#var raw_genres:PackedStringArray = raw_genre.split('&&')
		#for genre in raw_genres:
			#if genre is not String: continue
			#genres.append(genre)
	
		#genres = raw_genres

	var raw_copyright = data.get('copyright')
	if raw_copyright is String && not raw_copyright.is_empty(): copyright = raw_copyright
	else: copyright = 'None found'


func remove() -> void:
	artist.library.albums.erase(self)
	artist.albums.erase(self)
	for track:DBTrack in tracks: track.remove()


## Get all tracks in order of their disc number & track number.
##
## Returns a dictionary containing the disc number & array of [DBTrack] objects from that disc, ordered by track number.
func get_tracks_in_order() -> Dictionary[String,Array]:
	var result:Dictionary[String,Array] = {
		'1': [],
	}

	var track_list = tracks.duplicate()
	track_list.sort_custom(func(a:DBTrack, b:DBTrack) -> bool:
		return a.number < b.number
	)

	for track:DBTrack in track_list:
		var disc:String = str(track.disc)
		result.get_or_add(disc, [])
		result[disc].append(track)

	return result


## Returns the album cover [ImageTexture] or [code]null[/code] if it cannot be found.
func get_cover() -> ImageTexture:
	if _cover: return _cover
	var cover
	if FileAccess.file_exists(cover_path):
		var image = Image.load_from_file(cover_path)
		if image is Image:
			var album_cover_size: Vector2i
			match SessionManager.image_detail:
				0: album_cover_size = album_cover_size_1
				1: album_cover_size = album_cover_size_2
				2: album_cover_size = album_cover_size_3
			ImageUtils.limit_size(image, album_cover_size)
			image.generate_mipmaps()
			cover = ImageTexture.create_from_image(image)
	if not cover: return null

	# Save cover in memory for faster reloading.
	_cover = cover
	return cover


## Calls [param get_cover] in a separate thread then calls [param callback] with the result.
func get_cover_threaded(callback:Callable) -> void:
	if _cover:
		callback.call(_cover)
		return
	Async.create_thread(get_cover, callback)


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
