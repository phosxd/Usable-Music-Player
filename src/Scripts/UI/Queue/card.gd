extends PanelContainer


func _ready() -> void:
	highlight(false)


func init(track:DBTrack) -> void:
	%Name.text = track.name
	%Artist.text = track.artist.name
	%Length.text = DBTrack.get_track_position_formatted(track.length)
	track.album.get_cover_threaded(func(cover) -> void:
		%Image.texture = cover
	)


func highlight(on:bool) -> void:
	%Button.button_pressed = on
	if on:
		%Name.self_modulate = Color.WHITE
		%Artist.self_modulate = Color.WHITE
	else:
		var color := Color(0.75, 0.75, 0.75)
		%Name.self_modulate = color
		%Artist.self_modulate = color


func _on_button_pressed() -> void:
	PlayerManager.set_current_track(self.get_index())
	self.set_focus_mode(Control.FOCUS_ALL)
