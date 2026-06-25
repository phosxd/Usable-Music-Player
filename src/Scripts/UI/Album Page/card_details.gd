extends Container

signal init_completed

var track: DBTrack
var parent: Node
var button: Button

var initialized:bool = false


func init(parent_:Node, db_track:DBTrack, button_:Button) -> void:
	parent = parent_
	button = button_
	track = db_track
	if not track:
		queue_free.call_deferred()
		return
	if not self: return

	if %Name: %Name.text = track.name
	button.set_deferred('tooltip_text', track.name)
	if %'Track Number':
		if track.number == 0: %'Track Number'.hide()
		else: %'Track Number'.text = '%s' % (track.number)
	if %Artist: %Artist.text = track.actual_artist
	if %Length: %Length.text = DBTrack.get_track_position_formatted(track.length)
	if %Format: %Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	if not self: return
	if not parent: return

	initialized = true
	init_completed.emit()


func _on_context_menu_opened() -> void:
	%Options.set_pressed_no_signal(true)


func _on_context_menu_closed() -> void:
	if not %Options.is_hovered(): %Options.set_pressed_no_signal(false)


func _on_context_menu_id_pressed(_id:String) -> void:
	pass


func _on_artist_pressed() -> void:
	var artist:DBArtist = track.get_actual_artist()
	if not artist: artist = track.album.artist
	SessionManager.main_scene.set_tab('artist_page', artist)


func _on_options_toggled(toggled_on:bool) -> void:
	if toggled_on: parent.context_menu.show(parent.name)
