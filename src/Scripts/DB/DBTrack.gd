## Database item for music tracks.
## Use [param new_or_reuse] when instantiating.
class_name DBTrack extends RefCounted

## Parent album.
var album: DBAlbum
## Track absolute file path.
var path: String
## Number of bytes of file at [param path].
var file_size: int
## Track name.
var name: String
## Track actual artist name.
var actual_artist: String
## Track number.
var number: int
## Track album disc number.
var disc: int
## Track length.
var length: float
## Number of track channels.
var channels: int
## Track sample rate.
var sample_rate: float
## Track bit rate.
var bit_rate: float
## Track beats per minute.
var bpm: float
## Track comment.
var comment: String
## Last time the file was modified.
var last_modified_time: int

## Whether or not the DB entry is valid.
var valid := true


## Construct new DBTrack.
## Do not use [param raw_info].
func _init(album_:DBAlbum, path_:String, data:Dictionary) -> void:
	if path_ == '.dummy': return # Don't do any processing if is a dummy.
	if path_.is_empty() or not album_: remove()
	album = album_
	path = path_

	var raw_file_size = data.get('file_size')
	if raw_file_size is int: file_size = raw_file_size
	else: file_size = FileAccess.get_size(path)

	var raw_length = data.get('length')
	if raw_length is float: length = raw_length
	else: length = 0

	var raw_title = data.get('title')
	if raw_title is String && not raw_title.is_empty(): name = raw_title
	else: name = 'No title found'

	var raw_aa = data.get('actual_artist')
	if raw_aa is String && not raw_aa.is_empty(): actual_artist = raw_aa
	else: actual_artist = album.artist.name if album else ''

	var raw_disc = data.get('disc')
	if raw_disc is int: disc = raw_disc
	else: disc = 0

	var raw_number = data.get('number')
	if raw_number is int: number = raw_number
	else: number = 0

	var raw_lmt = data.get('last_modified_time')
	if raw_lmt is int: last_modified_time = raw_lmt
	else: last_modified_time = -1


func remove() -> void:
	LibraryManager.remove_track(path)


func get_stream() -> AudioStream:
	return LibraryManager.load_audio(path)


## Returns file system firendly name of the track.
func as_filename() -> String:
	return '%s__%s__%s__%s' % [album.artist.name.replace('/','_'), album.name.replace('/','_'), disc, number]


## Returns any stored lyrics for this track, or an empty string if none found.
func get_lyrics() -> String:
	var text = FileAccess.get_file_as_string(get_lyrics_path())
	return text


## Returns the path to the file storing this track's lyrics.
func get_lyrics_path() -> String:
	return LibraryManager.lyrics_path+'/'+as_filename()+'.txt'


func save_lyrics(lyrics:String) -> void:
	DirAccess.make_dir_recursive_absolute(LibraryManager.lyrics_path)
	var file := FileAccess.open(get_lyrics_path(), FileAccess.WRITE)
	file.store_string(lyrics)
	file.close()


static func get_track_position_formatted(value:float) -> String:
	var remainder := int(fmod(value,60))
	return '%s:%s' % [int(value/60), ('0' if remainder < 10 else '') + str(remainder)]
