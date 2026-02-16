extends PanelContainer

signal selected
const default_button_color := Color(1,1,1, 0.1)
const hover_button_color := Color(1,1,1, 0.2)

@onready var options_popup:PopupMenu = %Options.get_popup()
var track: DBTrack


func _ready() -> void:
	%Button.self_modulate = default_button_color
	options_popup.id_pressed.connect(_on_option_id_pressed)


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track.valid: _invalidate()
	%Name.text = track.name
	%Artist.text = '%s - by %s' % [track.album.name, track.artist.name]
	%'Track Number'.text = '%s' % (track.number+1)
	%Length.text = DBTrack.get_track_position_formatted(track.length)
	%Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	%Image.texture = track.album.cover


func _invalidate() -> void:
	self.hide()


func _on_button_pressed() -> void:
	selected.emit()


func _on_option_id_pressed(id:int) -> void:
	match id:
		0:
			selected.emit()
		1:
			PlayerManager.queue.insert(PlayerManager.queue_position+1, track)
		2: PlayerManager.add_to_queue(track)
		3: OS.shell_show_in_file_manager(track.path)
		4: init(LibraryManager.rescan_track(track))


func _on_button_mouse_entered() -> void:
	%Button.self_modulate = hover_button_color


func _on_button_mouse_exited() -> void:
	%Button.self_modulate = default_button_color


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_pressed('right_click'):
		var mouse_position:Vector2i = DisplayServer.mouse_get_position()
		options_popup.popup(Rect2(
			mouse_position.x-50,
			mouse_position.y-10,
			0,
			0,
		))
