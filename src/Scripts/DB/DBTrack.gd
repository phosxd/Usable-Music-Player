## Database item for music tracks.
## Use [param new_or_reuse] when instantiating.
class_name DBTrack extends RefCounted

## Parent album.
var album: DBAlbum
## Track absolute file path.
var path:String = ''
## Number of bytes of file at [param path].
var file_size:int = 0
## Track name.
var name:String = ''
## Track actual artist name.
var actual_artist:String = ''
## Track number.
var number:int = 0
## Track album disc number.
var disc:int = 0
## Track length.
var length:float = 0.0
## Number of track channels.
var channels:int = 0
## Track sample rate.
var sample_rate:float = 0.0
## Track bit rate.
var bit_rate:float = 0.0
## Track beats per minute.
var bpm:float = 0.0
var replay_gain:float = 0.0
## Track comment.
var comment: String
## Last time the file was modified.
var last_modified_time: int

## Whether or not the DB entry is valid.
var valid := true


## Construct new DBTrack.
## Do not use [param raw_info].
func _init(album_:DBAlbum, data:Dictionary) -> void:
	if album_ == null: return # Don't do any processing if is a dummy.
	album = album_
	album.tracks.append(self)
	album.artist.library.tracks.append(self)
	update_data(data)


func update_data(data:Dictionary) -> void:
	path = data.get('path','')

	var raw_file_size = data.get('file_size')
	if raw_file_size is int: file_size = raw_file_size
	else: file_size = FileAccess.get_size(path)

	var raw_length = data.get('length')
	if raw_length is float: length = raw_length
	else: length = 0

	var raw_name = data.get('name')
	if raw_name is String && not raw_name.is_empty(): name = raw_name
	else: name = ''

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

	replay_gain = data.get('replay_gain',0.0)


func remove() -> void:
	album.artist.library.tracks.erase(self)
	album.tracks.erase(self)


func get_stream() -> AudioStream:
	return LibraryManager.load_audio(path)


## Returns file system firendly name of the track.
func as_filename() -> String:
	return '%s__%s__%s__%s' % [album.artist.name.replace('/','_'), album.name.replace('/','_'), disc, number]


func as_uid() -> String:
	if not album.artist.library: return ''
	var library_id:String = album.artist.library.id
	return ':'.join([
		library_id,
		album.artist.name,
		album.name,
		str(disc),
		str(number),
		str(length),
		str(file_size),
	])


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
