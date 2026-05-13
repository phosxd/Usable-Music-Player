extends Container

signal init_completed

var track: DBTrack
var parent: Node
var button: Button

var initialized:bool = false


func _ready() -> void:
	self.parent.context_menu.id_pressed.connect(_on_option_id_pressed)
	self.parent.context_menu.closed.connect(func() -> void:
		if self.parent.context_menu.current_instance_id != self.parent.name: return
		%Options.button_pressed = false
	)


func init(parent_:Node, db_track:DBTrack, button_:Button) -> void:
	parent = parent_
	button = button_
	track = db_track
	if not self.track:
		self.queue_free.call_deferred()
		return
	if not self: return

	if %Name: %Name.text = track.name
	button.set_deferred('tooltip_text', track.name)
	if %'Track Number':
		if track.number == 0: %'Track Number'.hide()
		else: %'Track Number'.text = '%s' % (track.number)
	if %Artist: %Artist.text = track.actual_artist
	if %Album: %Album.text = track.album.name
	if %Length: %Length.text = DBTrack.get_track_position_formatted(track.length)
	if %Format: %Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	var cover = track.album.get_cover() if track.album else DBAlbum.default_cover
	if not self: return
	if %Image: %Image.texture = cover
	if not self.parent: return
	set_mode(self.parent.get('selected_mode'))
	initialized = true
	init_completed.emit()


func set_mode(mode:int) -> void:
	parent.set('selected_mode', mode)
	if mode == 0: # Detailed.
		%Album.show()
		%Image.show()
		%'Image Sep'.hide()
	if mode == 1: # Minimal.
		%Album.hide()
		%Image.hide()
		%'Image Sep'.show()


func _on_option_id_pressed(id:String) -> void:
	if parent.context_menu.current_instance_id != parent.name: return
	match id:
		'play':
			PlayerManager.auto_queue_start_index = -1
			parent.selected.emit()
		'play_next':
			PlayerManager.insert_to_queue(PlayerManager.queue_position+1, track)
			if PlayerManager.auto_queue_start_index == -1:
				PlayerManager.auto_queue_start_index = PlayerManager.queue_position+2
			else:
				PlayerManager.auto_queue_start_index += 1
		'add_to_queue':
			if PlayerManager.auto_queue_start_index > PlayerManager.queue_position:
				PlayerManager.insert_to_queue(PlayerManager.auto_queue_start_index, track)
				PlayerManager.auto_queue_start_index += 1
			else:
				PlayerManager.add_to_queue(track)
		'show_album':
			SessionManager.main_scene.set_tab('album_page', track.album)
		'show_in_files':
			OS.shell_show_in_file_manager(track.get_full_path())


func _on_album_pressed() -> void:
	SessionManager.main_scene.set_tab('album_page', track.album)


func _on_artist_pressed() -> void:
	var artist:DBArtist = track.get_actual_artist()
	if not artist: artist = track.album.artist
	SessionManager.main_scene.set_tab('artist_page', artist)


func _on_options_toggled(toggled_on:bool) -> void:
	if toggled_on: parent.context_menu.show(parent.name)
