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


var track_players:Array[TrackPlayer] = []
## Queued tracks.
var queue:Array[DBTrack] = []
var queue_position:int = 0


func _ready() -> void:
	pass


func _process(_delta:float) -> void:
	pass


func set_playing(playing:bool) -> void:
	if playing: play_requested.emit()
	else: pause_requested.emit()


func set_current_track(track_queue_position:int) -> void:
	queue_position = track_queue_position
	current_track_updated.emit(queue_position)
	track_progress_updated.emit(0)


func add_to_queue(track:DBTrack) -> void:
	if not queue.has(track): queue.append(track)
	queue_updated.emit(queue)


func remove_from_queue(track:DBTrack) -> void:
	queue.erase(track)
	queue_updated.emit(queue)
