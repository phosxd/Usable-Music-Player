extends PanelContainer

signal selected

enum CardMode {
	detailed,
	minimal,
}

@onready var context_menu:ContextMenu = SessionManager.context_menus.track_card
var track: DBTrack
var selected_mode := CardMode.detailed


func _ready() -> void:
	$HBox.hide() # Hide elements.
	context_menu.id_pressed.connect(_on_option_id_pressed)
	context_menu.closed.connect(func() -> void:
		if context_menu.current_instance_id != name: return
		%Options.button_pressed = false
	)


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track:
		self.queue_free()
		return

	%Name.text = track.name
	%Button.tooltip_text = track.name
	if track.number == 0: %'Track Number'.hide()
	else: %'Track Number'.text = '%s' % (track.number)
	%Artist.text = track.actual_artist
	%Album.text = track.album.name
	%Length.text = DBTrack.get_track_position_formatted(track.length)
	%Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	%Image.texture = track.album.get_cover() if track.album else DBAlbum.default_cover
	set_mode(selected_mode)


func set_mode(mode:CardMode) -> void:
	selected_mode = mode
	if mode == CardMode.detailed:
		%Album.show()
		%Image.show()
		%'Image Sep'.hide()
	if mode == CardMode.minimal:
		%Album.hide()
		%Image.hide()
		%'Image Sep'.show()


func _on_button_pressed() -> void:
	PlayerManager.auto_queue_start_index = -1
	selected.emit()


func _on_option_id_pressed(id:int) -> void:
	if context_menu.current_instance_id != name: return
	match id:
		0: # Play.
			PlayerManager.auto_queue_start_index = -1
			selected.emit()
		1: # Play next.
			PlayerManager.insert_to_queue(PlayerManager.queue_position+1, track)
			if PlayerManager.auto_queue_start_index == -1:
				PlayerManager.auto_queue_start_index = PlayerManager.queue_position+2
			else:
				PlayerManager.auto_queue_start_index += 1
		2: # Add to queue.
			if PlayerManager.auto_queue_start_index > PlayerManager.queue_position:
				PlayerManager.insert_to_queue(PlayerManager.auto_queue_start_index, track)
				PlayerManager.auto_queue_start_index += 1
			else:
				PlayerManager.add_to_queue(track)
		3: # Show album.
			SessionManager.main_scene.set_tab('album_page', track.album)
		4: # Show in files.
			OS.shell_show_in_file_manager(track.get_full_path())


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		%Options.button_pressed = true


func _on_options_toggled(toggled_on:bool) -> void:
	if toggled_on: context_menu.show(name)


func _on_artist_pressed() -> void:
	SessionManager.main_scene.set_tab('artist_page', track.album.artist)


func _on_album_pressed() -> void:
	SessionManager.main_scene.set_tab('album_page', track.album)
