extends Control

var is_dragging:bool = false


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
	%Button.set_pressed_no_signal(on)
	if on:
		%Name.self_modulate = Color.WHITE
		%Artist.self_modulate = Color.WHITE
	else:
		var color := Color(0.75, 0.75, 0.75)
		%Name.self_modulate = color
		%Artist.self_modulate = color


func _on_button_pressed() -> void:
	PlayerManager.set_current_track(self.get_index())
	%Button.set_pressed_no_signal(true)
	self.set_focus_mode(Control.FOCUS_ALL)


func _on_move_up_pressed() -> void:
	get_parent().move_child(self, get_index()-1)


func _on_move_down_pressed() -> void:
	get_parent().move_child(self, get_index()+1)


func _on_drag_button_button_down() -> void:
	is_dragging = true
	var list = self.get_parent()
	if list is not ReorderableContainer: return
	list._focus_child = self
	list._is_press = true


func _on_drag_button_button_up() -> void:
	is_dragging = false
	var list = self.get_parent()
	if list is not ReorderableContainer: return
	list._is_press = false
