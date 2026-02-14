extends Node

## Emitted when the queue has been updated. [param queue] is an array of DBTrack objects.
signal queue_updated(queue:Array[DBTrack])
## Emitted when play has been requested.
signal play_requested()
## Emitted when pause has been requested.
signal pause_requested()
signal current_track_updated(queue_position:int)
## Emitted when the track has progressed (E.g. during playback). [param track_prgress] is the track progress in seconds.
signal track_progress_updated(track_progress:float)


## Queued tracks.
var queue:Array[DBTrack] = []
var queue_position:int = 0
var audio_stream_player: AudioStreamPlayer
var track_progress: float


func _ready() -> void:
	LibraryManager.load_library_from_cache()
	audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.mix_target = AudioStreamPlayer.MIX_TARGET_SURROUND
	self.add_child(audio_stream_player)

	var raw_open_track = LibraryManager.database.get('open_track')
	if raw_open_track is Dictionary:
		var artist_name:String = raw_open_track.get('artist')
		if not artist_name.is_empty():
			var artist := DBArtist.new(artist_name)
			var album_name:String = raw_open_track.get('album')
			if not album_name.is_empty():
				var album := DBAlbum.new(artist, album_name)
				var track_number = raw_open_track.get('track_number',null)
				if track_number is int:
					var track := DBTrack.new(artist, album, track_number)
					add_to_queue(track)
					set_current_track(0)
					var raw_track_progress = raw_open_track.get('track_progress',0)
					set_track_progress(raw_track_progress)


func _process(_delta:float) -> void:
	if audio_stream_player.playing:
		track_progress = audio_stream_player.get_playback_position()
		track_progress_updated.emit(track_progress)


func get_current_track() -> DBTrack:
	return queue.get(queue_position)


func set_playing(playing:bool) -> void:
	if playing:
		audio_stream_player.play(track_progress)
		play_requested.emit()
	else:
		audio_stream_player.stop()
		pause_requested.emit()


func set_volume(value:float) -> void:
	audio_stream_player.volume_db = linear_to_db(value/100.0)


func set_track_progress(progress:float) -> void:
	track_progress = progress
	audio_stream_player.seek(progress)
	track_progress_updated.emit(progress)


func set_current_track(track_queue_position:int) -> void:
	var track = queue.get(track_queue_position)
	if track is not DBTrack:
		return
	audio_stream_player.stream = track.get_stream()
	queue_position = track_queue_position
	current_track_updated.emit(queue_position)
	set_track_progress(0)


func skip_forward() -> void:
	set_current_track(queue_position+1)


func skip_backward() -> void:
	if track_progress == 0.0:
		set_current_track(queue_position-1)
	else:
		set_track_progress(0.0)


func add_to_queue(track:DBTrack) -> void:
	if not queue.has(track): queue.append(track)
	queue_updated.emit(queue)


func remove_from_queue(track:DBTrack) -> void:
	queue.erase(track)
	queue_updated.emit(queue)


func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var track = get_current_track()
		if track == null: return

		LibraryManager.database.open_track = {
			'artist': track.artist.name,
			'album': track.album.name,
			'track_number': track.number,
			'track_progress': track_progress,
		}
		LibraryManager.save_database()
		get_tree().quit()
