extends PanelContainer

signal selected
enum CardMode {
	detailed,
	minimal,
}
const default_button_color := Color(1,1,1, 0.1)
const hover_button_color := Color(1,1,1, 0.2)

@onready var options_popup:PopupMenu = %Options.get_popup()
var track: DBTrack
var selected_mode := CardMode.detailed


func _ready() -> void:
	%Button.self_modulate = default_button_color
	options_popup.id_pressed.connect(_on_option_id_pressed)


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track.valid: _invalidate()
	%Name.text = track.name
	%'Track Number'.text = '%s' % (track.number+1)
	%Length.text = DBTrack.get_track_position_formatted(track.length)
	%Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	%Image.texture = track.album.get_cover()
	set_mode(selected_mode)


func set_mode(mode:CardMode) -> void:
	selected_mode = mode
	if mode == CardMode.detailed:
		%Artist.text = '%s - by %s' % [track.album.name, track.actual_artist]
		%Image.show()
		%'Image Sep'.hide()
	if mode == CardMode.minimal:
		%Artist.text = '%s' % [track.artist.name]
		%Image.hide()
		%'Image Sep'.show()


func _invalidate() -> void:
	self.hide()


func _on_button_pressed() -> void:
	PlayerManager.auto_queue_start_index = -1
	selected.emit()


func _on_option_id_pressed(id:int) -> void:
	match id:
		0:
			PlayerManager.auto_queue_start_index = -1
			selected.emit()
		1:
			PlayerManager.insert_to_queue(PlayerManager.queue_position+1, track)
			if PlayerManager.auto_queue_start_index == -1:
				PlayerManager.auto_queue_start_index = PlayerManager.queue_position+2
			else:
				PlayerManager.auto_queue_start_index += 1
		2:
			if PlayerManager.auto_queue_start_index > PlayerManager.queue_position:
				PlayerManager.insert_to_queue(PlayerManager.auto_queue_start_index, track)
				PlayerManager.auto_queue_start_index += 1
			else:
				PlayerManager.add_to_queue(track)
		3: OS.shell_show_in_file_manager(track.path)
		4: init(LibraryManager.rescan_track(track))


func _on_button_mouse_entered() -> void:
	if not %Button: return
	%Button.self_modulate = hover_button_color


func _on_button_mouse_exited() -> void:
	if not %Button: return
	%Button.self_modulate = default_button_color


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_pressed('right_click'):
		var mouse_position:Vector2i = get_global_mouse_position()
		options_popup.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
		options_popup.popup(Rect2(
			mouse_position.x-50,
			mouse_position.y+10,
			0,
			0,
		))
