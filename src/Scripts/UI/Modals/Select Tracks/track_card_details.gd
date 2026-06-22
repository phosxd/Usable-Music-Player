extends HBoxContainer

signal init_completed

var track: DBTrack
var parent: Node
var button: Button

var initialized:bool = false


func init(parent_:Node, track_:DBTrack, button_:Button) -> void:
	parent = parent_
	track = track_
	button = button_
	if not track:
		queue_free.call_deferred()
		return
	if not self: return

	%Name.text = track.name
	%Album.text = track.album.name
	%Artist.text = track.album.artist.name
	%Image.texture = track.album.get_cover()
	button.set_deferred('tooltip_text', track.name)
	
	if not self or not parent: return
	initialized = true
	init_completed.emit()
