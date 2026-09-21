extends Node

const minilog_importance := MiniLog.Importance.None

## Emitted when the queue has been updated via queue control functions.
## Does not emit when queue is changed manually.
signal queue_updated(code:QueueUpdateCode, data:Variant)
## Emitted when play has been requested.
signal play_requested()
## Emitted when pause has been requested.
signal pause_requested()
signal current_track_updated(track_queue_position:int, track:DBTrack)
signal current_track_load_started()
signal current_track_load_finished()
## Emitted when the track has progressed (E.g. during playback). [param track_prgress] is the track progress in seconds.
signal track_progress_updated(track_progress:float)
## Emitted when the volume has changed.
signal volume_updated(value:float)
## [param db] is a float with a minimum of -100.
signal track_peak_volume_changed(db:float)
signal replay_gain_updated(value:float)

enum QueueUpdateCode {
	Set,
	Add,
	Remove,
	Insert,
	Shuffle,
}

enum LoopMode {
	OFF,
	TRACK,
	QUEUE,
}

const volume_step_ammount:float = 2.5

## Queued tracks.
var queue:Array[DBTrack] = []
var queue_position:int = 0
var auto_queue_start_index:int = -1
var audio_stream_player: AudioStreamPlayer
var current_track_loading:bool = false
var track_progress: float
var last_peak_volume: float # Not the track's total peak volume, instead this is the immediate loudness of the track.
var track_peak:float = 0.0 # Track's peak volume, the loudest the track has been since playing it.
var loop_mode := LoopMode.OFF
var replay_gain:float = 0.0:
	set(value):
		replay_gain = value
		volume = volume
		replay_gain_updated.emit(value)
var volume:float = 100.0:
	set(value):
		value = min(100,max(0,value))
		volume = value
		audio_stream_player.volume_linear = (value*0.01)
		audio_stream_player.volume_db += replay_gain
		if SessionManager.get_var('replay_gain_mode') != 0 && replay_gain != 0.0:
			audio_stream_player.volume_db += SessionManager.replay_gain_preamp
		volume_updated.emit(value)

## Queue index to stop playing at. If [code]-1[/code], will do nothing.
var stop_at_index:int = -1

var is_playing:bool = false
var is_shuffled:bool = false

var next_track_stream:AudioStream = null # Preloaded stream for next track in queue.
var loading_next_track_stream:bool = false


func _ready() -> void:
	SessionManager.value_changed.connect(_on_session_manager_value_changed)

	audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.bus = &'Master'
	audio_stream_player.mix_target = AudioStreamPlayer.MIX_TARGET_SURROUND
	audio_stream_player.finished.connect(_current_track_finished)
	add_child(audio_stream_player)

	# Send updates to MPRIS server every half second.
	while true:
		await get_tree().create_timer(0.5).timeout
		PyInterface.update_mpris_data({
			'track_position': snappedf(track_progress,0.01),
		})


func _process(_delta:float) -> void:
	if Engine.get_process_frames() % 5 != 0: return

	# Emit loudness changes.
	if audio_stream_player.playing or last_peak_volume != -200:
		var peak_volume:float = MathUtils.transfer_range_of_value(Vector2(-200,0), Vector2(-100,0), AudioServer.get_bus_peak_volume_left_db(0,0)+AudioServer.get_bus_peak_volume_right_db(0,0))
		if peak_volume != last_peak_volume:
			if peak_volume > track_peak: track_peak = peak_volume # Update track peak.
			track_peak_volume_changed.emit(peak_volume)
		last_peak_volume = peak_volume

	# Update track progress.
	if audio_stream_player.playing:
		track_progress = audio_stream_player.get_playback_position()
		track_progress_updated.emit(track_progress)
		# Preload next track if nearing end of this track.
		if track_progress > audio_stream_player.stream.get_length()*0.75 && next_track_stream == null && not loading_next_track_stream:
			var next_track:DBTrack = queue.get(queue_position+1)
			if next_track:
				loading_next_track_stream = true
				Async.create_thread(func() -> void:
					next_track_stream = next_track.get_stream()
					loading_next_track_stream = false
				)


func _on_session_manager_value_changed(property_name:String, source_name:String) -> void:
	if source_name != 'base' or property_name != 'replay_gain_mode': return

	# Update replay gain.
	var track:DBTrack = get_current_track()
	match SessionManager.get_var('replay_gain_mode'):
		0: # None.
			if replay_gain != 0.0: replay_gain = 0.0
		1: # Track.
			if track.replay_gain != replay_gain: replay_gain = track.replay_gain
		2: # Album.
			if track.album.replay_gain != replay_gain: replay_gain = track.album.replay_gain
		3: # Auto.
			if track.album.replay_gain != replay_gain:
				replay_gain = track.album.replay_gain
			if track.replay_gain != replay_gain:
				replay_gain = track.replay_gain
	


## Returns track currently selected in the queue or [code]null[/code] if none selected.
func get_current_track() -> DBTrack:
	if queue_position >= queue.size(): return
	return queue.get(queue_position)


func set_playing(playing:bool) -> void:
	is_playing = playing
	if playing:
		audio_stream_player.play(track_progress)
		play_requested.emit()
	else:
		audio_stream_player.stop()
		pause_requested.emit()

	PyInterface.update_mpris_data({
		'playback_status': 'Playing' if playing else 'Paused',
	})


func set_track_progress(progress:float) -> void:
	track_progress = progress
	audio_stream_player.seek(progress)
	track_progress_updated.emit(progress)


## Set the selected track in the [member queue]. If [param save_session] is [code]true[/code], will save the [SessionManager] session after loading the track.
func set_current_track(track_queue_position:int, save_session:bool=true, use_preloaded_next_stream:bool=false) -> void:
	if track_queue_position >= queue.size() or track_queue_position < 0: return
	var track = queue.get(track_queue_position)
	if track is not DBTrack: return
	set_track_progress(0)
	audio_stream_player.stop()
	queue_position = track_queue_position
	current_track_updated.emit(track_queue_position, track)
	current_track_loading = true
	current_track_load_started.emit()
	
	var post_load = func(_result) -> void:
		# Set playing.
		if is_playing && track_queue_position != stop_at_index: set_playing(true)
		else:
			set_playing(false)
			stop_at_index = -1
		# Emit current track load finished.
		current_track_load_finished.emit()
		current_track_loading = false
		# Save session.
		if save_session: SessionManager.save_session()
		# Send metadata to MPRIS server.
		PyInterface.update_mpris_data({
			'track_title': track.name,
			'track_album': track.album.name,
			'track_artist': track.album.artist.name,
			'track_length': track.length,
			'art_url': 'file://%s' % track.album.cover_path,
		})

	if use_preloaded_next_stream && next_track_stream:
		audio_stream_player.stream = next_track_stream
		next_track_stream = null
		post_load.call(null)
	else:
		Async.create_thread(func() -> void:
			var stream:AudioStream = track.get_stream()
			if get_current_track() != track: return
			audio_stream_player.set_deferred('stream', stream)
		,post_load)


## Skip to the next track in the [member queue].
func next() -> void:
	if loop_mode == LoopMode.QUEUE && queue.size() == queue_position+1:
		set_current_track(0)
	else:
		set_current_track(queue_position+1, true, true)


## Skip to the previous track in the [member queue].
func previous() -> void:
	if track_progress > 3.0:
		set_track_progress(0.0)
	else:
		set_current_track(queue_position-1)


func volume_step_up() -> void:
	volume += volume_step_ammount


func volume_step_down() -> void:
	volume -= volume_step_ammount


## Replaces queue with [param new_queue] & selects the [param track] & plays it.
func set_queue_and_track(new_queue:Array[DBTrack], track:DBTrack) -> void:
	set_queue(new_queue, track)
	set_current_track(queue.find(track))
	if is_shuffled: shuffle_queue(track)
	await current_track_load_finished
	if get_current_track() != track: return
	set_playing(true)


## Set the queue to [param new_queue]. If queue size is higher than the set limit, the necessary tracks will be removed from the end of the queue.
##
## Use [param anchor] to begin from a specific track when truncating.
func set_queue(new_queue:Array[DBTrack], anchor:DBTrack=null) -> void:
	MiniLog.pro('Set queue.', PlayerManager)
	is_shuffled = false

	var queue_size_limit:int = SessionManager.get_var('queue_size_limit')
	var anchor_index:int = new_queue.find(anchor) if anchor else -1
	if anchor && anchor_index != -1 && new_queue.size() >= queue_size_limit:
		queue = new_queue.slice(anchor_index, queue_size_limit+anchor_index)
	else:
		queue = new_queue.slice(0, queue_size_limit)

	queue_updated.emit(QueueUpdateCode.Set, null)


## Add a track to the very end of the [member queue].
func add_to_queue(track:DBTrack, emit:bool=true) -> void:
	queue.append(track)
	if queue.size() >= SessionManager.get_var('queue_size_limit'):
		remove_from_queue(queue[0 if queue_position != 0 else 1])

	if emit: queue_updated.emit(QueueUpdateCode.Add, track)


## Add a track to the end of the [member queue], or before the start of the [member auto_queue_start_index].
func add_to_queue_with_context(track:DBTrack, emit:bool=true) -> void:
	if auto_queue_start_index > queue_position:
		insert_to_queue(auto_queue_start_index, track, emit)
		auto_queue_start_index += 1
	else:
		add_to_queue(track, emit)


func add_next_in_queue(track:DBTrack, emit:bool=true) -> void:
	insert_to_queue(queue_position+1, track, emit)


func add_next_in_queue_with_context(track:DBTrack, emit:bool=true) -> void:
	insert_to_queue(queue_position+1, track, emit)
	if auto_queue_start_index == -1:
		auto_queue_start_index = queue_position+2
	else:
		auto_queue_start_index += 1


func remove_from_queue(track:DBTrack, emit:bool=true) -> void:
	var index:int = queue.find(track)
	if index == -1: return
	queue.remove_at(index)
	queue_updated.emit(QueueUpdateCode.Remove, {'track':track,'index':index})


func insert_to_queue(position:int, track:DBTrack, emit:bool=true) -> void:
	if position > queue.size():
		queue.append(track)
	else:
		queue.insert(position, track)
		if position < PlayerManager.queue_position:
			PlayerManager.queue_position += 1
	if queue.size() >= SessionManager.get_var('queue_size_limit'):
		remove_from_queue(queue[0 if queue_position != 0 else 1])

	if emit: queue_updated.emit(QueueUpdateCode.Insert, {'track':track,'index':position})


## Shuffles the queue. If [param anchor] track is used, will shuffle the queue & move anchor track to the beginning.
func shuffle_queue(anchor:DBTrack=null, emit:bool=true) -> void:
	MiniLog.pro('Shuffling queue.', PlayerManager)
	is_shuffled = true
	queue.shuffle()
	if anchor:
		queue.erase(anchor)
		insert_to_queue(0, anchor, emit)
		var track_progress_:float = track_progress
		set_current_track(0)
		set_track_progress(track_progress_)
	if emit: queue_updated.emit(QueueUpdateCode.Shuffle, null)


func _current_track_finished() -> void:
	MiniLog.pro('Track finished.', PlayerManager)
	if queue_position+1 >= queue.size(): is_playing = false
	if loop_mode == LoopMode.TRACK: set_playing(true)
	elif loop_mode == LoopMode.QUEUE:
		next()
		set_playing(true)
	else: next()

	if SessionManager.get_var('send_track_finished_notif'):
		var track:DBTrack = get_current_track()
		if track:
			SystemNotif.send(
				'Now playing...',
				'%s - by %s' % [track.name, track.album.artist.name],
				SystemNotif.Urgency.Low,
				track.album.cover_path,
				2.75,
			)
