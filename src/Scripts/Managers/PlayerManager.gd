extends Node

## Emitted when the queue has been updated via queue control functions.
## Does not emit when queue is changed manually.
signal queue_updated()
## Emitted when play has been requested.
signal play_requested()
## Emitted when pause has been requested.
signal pause_requested()
signal current_track_updated(queue_position:int)
## Emitted when the track has progressed (E.g. during playback). [param track_prgress] is the track progress in seconds.
signal track_progress_updated(track_progress:float)
## [param db] is a float with a minimum of -100.
signal track_peak_volume_changed(db:float)

enum LoopMode {
	OFF,
	TRACK,
	QUEUE,
}


## Queued tracks.
var queue:Array[DBTrack] = []
var queue_position:int = 0
var auto_queue_start_index:int = -1
var audio_stream_player: AudioStreamPlayer
var track_progress: float
var last_peak_volume: float
var loop_mode := LoopMode.OFF


func _ready() -> void:
	LibraryManager.load_library_from_cache()
	audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.bus = &'Master'
	audio_stream_player.mix_target = AudioStreamPlayer.MIX_TARGET_SURROUND
	audio_stream_player.finished.connect(_current_track_finished)
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
	var peak_volume:float = MathUtils.transfer_range_of_value(Vector2(-200,0), Vector2(-100,0), AudioServer.get_bus_peak_volume_left_db(0,0)+AudioServer.get_bus_peak_volume_right_db(0,0))
	if peak_volume != last_peak_volume:
		track_peak_volume_changed.emit(peak_volume)
	last_peak_volume = peak_volume

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
	SessionManager.track_progress = progress


func set_current_track(track_queue_position:int) -> void:
	if track_queue_position > queue.size()-1 or track_queue_position < 0: return
	var track = queue.get(track_queue_position)
	if track is not DBTrack or track.valid == false:
		return
	audio_stream_player.stream = track.get_stream()
	queue_position = track_queue_position
	current_track_updated.emit(queue_position)
	SessionManager.track = track
	set_track_progress(0)


func skip_forward() -> void:
	var is_playing:bool = audio_stream_player.playing
	if loop_mode == LoopMode.QUEUE && queue.size() == queue_position+1:
		set_current_track(0)
	else:
		set_current_track(queue_position+1)
	if is_playing:
		set_playing(true)


func skip_backward() -> void:
	if track_progress > 3.0:
		set_track_progress(0.0)
	else:
		var is_playing:bool = audio_stream_player.playing
		set_current_track(queue_position-1)
		if is_playing:
			set_playing(true)


func set_queue(new_queue:Array[DBTrack]) -> void:
	queue = new_queue
	queue_updated.emit()


func add_to_queue(track:DBTrack) -> void:
	if not queue.has(track):
		queue.append(track)
		queue_updated.emit()


func remove_from_queue(track:DBTrack) -> void:
	queue.erase(track)
	queue_updated.emit()


func insert_to_queue(position:int, track:DBTrack) -> void:
	if not queue.has(track):
		queue.insert(position, track)
		queue_updated.emit()


func shuffle_queue() -> void:
	queue.shuffle()
	queue_updated.emit()


func _current_track_finished() -> void:
	audio_stream_player.playing = true
	if loop_mode == LoopMode.TRACK: audio_stream_player.play()
	else: skip_forward()
