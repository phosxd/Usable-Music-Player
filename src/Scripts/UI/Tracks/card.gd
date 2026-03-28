extends PanelContainer

signal selected
enum CardMode {
	detailed,
	minimal,
}

@onready var context_menu := ContextMenu.new([
	{
		'type': 'button',
		'text': 'Play (clear queue)',
		'icon': SessionManager.get_icon('play'),
	},
	{
		'type': 'button',
		'text': 'Play Next',
		'icon': SessionManager.get_icon('queue_play_next'),
	},
	{
		'type': 'button',
		'text': 'Add To Queue',
		'icon': SessionManager.get_icon('queue_add_to_queue'),
	},
	{
		'type': 'button',
		'text': 'Show Album',
		'icon': SessionManager.get_icon('folder'),
	},
	{
		'type': 'button',
		'text': 'Show In Files',
		'icon': SessionManager.get_icon('folder'),
	},
	{
		'type': 'button',
		'text': 'Rescan',
		'icon': SessionManager.get_icon('modifiers'),
	},
])
var track: DBTrack
var selected_mode := CardMode.detailed


func _ready() -> void:
	context_menu.id_pressed.connect(_on_option_id_pressed)
	context_menu.closed.connect(func() -> void:
		%Options.button_pressed = false
	)


func _exit_tree() -> void:
	context_menu.queue_free()


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track.valid: _invalidate()
	%Name.text = track.name
	if track.number == 0: %'Track Number'.hide()
	else: %'Track Number'.text = '%s' % (track.number)
	%Length.text = DBTrack.get_track_position_formatted(track.length)
	%Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	%Image.texture = track.album.get_cover() if track.album else DBAlbum.default_cover
	set_mode(selected_mode)


func set_mode(mode:CardMode) -> void:
	selected_mode = mode
	if mode == CardMode.detailed:
		%Artist.text = '%s - by %s' % [track.album.name, track.actual_artist]
		%Image.show()
		%'Image Sep'.hide()
	if mode == CardMode.minimal:
		%Artist.text = '%s' % [track.actual_artist]
		%Image.hide()
		%'Image Sep'.show()


func _invalidate() -> void:
	self.hide()


func _on_button_pressed() -> void:
	PlayerManager.auto_queue_start_index = -1
	selected.emit()


func _on_option_id_pressed(id:int) -> void:
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
			OS.shell_show_in_file_manager(track.path)
		5: # Rescan.
			LibraryManager.rescan_track(track)
			SessionManager.main_scene.refresh_tab()


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		%Options.button_pressed = true


func _on_options_toggled(toggled_on:bool) -> void:
	if toggled_on: context_menu.show()
