class_name DBAlbum extends RefCounted

enum DominantColorMethod {
	EASY,
	ACCURATE,
	ACCURATE_BLEND,
}

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
## Can return null if track cannot be found.
func get_track(track_number:int) -> DBTrack:
	var raw_artist:Dictionary = LibraryManager.database.artists.get(artist.name,{})
	var raw_album:Dictionary = raw_artist.get('albums',{}).get(name,{})
	var raw_track = raw_album.get('tracks',[]).get(track_number)
	if raw_album is not Dictionary:
		_invalidate()
		return null

	return DBTrack.new(artist, self, track_number, raw_track)


func get_album_dominant_color(method:=DominantColorMethod.ACCURATE_BLEND) -> Color:
	var image:Image = cover.get_image()
	if method == DominantColorMethod.EASY:
		image.crop(1,1)
		return image.get_pixel(0,0)

	if method in [DominantColorMethod.ACCURATE, DominantColorMethod.ACCURATE_BLEND]:
		image.resize(8,8, Image.INTERPOLATE_BILINEAR)
		var image_size:Vector2i = image.get_size()
		var colors:Dictionary[Color,int] = {}
		# Iterate on each pixel & count the instances.
		for x in image_size.x:
			for y in image_size.y:
				var pixel:Color = image.get_pixel(x,y)
				if pixel.a != 1.0: continue # Exclude transparent pixels.
				colors.get_or_add(pixel, 0)
				colors[pixel] += 1
		var sorted:Array[int] = colors.values(); sorted.sort()
		# Return white if no colors found.
		if sorted.is_empty(): return Color.WHITE
		# Get top colors & return it.
		var color:Color = colors.find_key(sorted[-1])
		colors.erase(color)
		sorted.remove_at(-1)
		# Blend remaining colors.
		if method == DominantColorMethod.ACCURATE_BLEND:
			var sorted_reversed:Array[int] = sorted.duplicate(); sorted_reversed.reverse()
			for count:int in sorted_reversed:
				var blend_color:Color = colors.find_key(count)
				colors.erase(blend_color)
				blend_color.a = 0.5/count
				color = color.blend(blend_color)
		return color

	return Color.WHITE
