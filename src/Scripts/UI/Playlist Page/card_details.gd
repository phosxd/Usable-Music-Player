extends Container

signal init_completed

var track: DBTrack
var parent: Node
var button: Button

var initialized:bool = false
var is_dragging:bool = false


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
	if %Artist: %Artist.text = track.actual_artist
	if %Album: %Album.text = track.album.name
	if %Length: %Length.text = DBTrack.get_track_position_formatted(track.length)
	if %Format: %Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	var cover:ImageTexture = track.album.get_cover()
	if %Image: %Image.texture = cover if cover is Texture2D else null
	if not self: return
	if not parent: return

	initialized = true
	init_completed.emit()


func _on_context_menu_opened() -> void:
	%Options.set_pressed_no_signal(true)


func _on_context_menu_closed() -> void:
	if not %Options.is_hovered(): %Options.set_pressed_no_signal(false)


func _on_context_menu_id_pressed(id:String) -> void:
	var playlist = parent.get_meta('playlist', null)
	var scene = parent.get_meta('scene', null)
	if playlist is not DBPlaylist or scene is not Node: return
	playlist = playlist as DBPlaylist
	scene = scene as Node

	match id:
		'remove':
			playlist.track_ids.remove_at(parent.get_index())
			scene.sort()


func _on_album_pressed() -> void:
	SessionManager.main_scene.set_tab('album_page', track.album)


func _on_artist_pressed() -> void:
	var artist:DBArtist = track.get_actual_artist()
	if not artist: artist = track.album.artist
	SessionManager.main_scene.set_tab('artist_page', artist)


func _on_options_toggled(toggled_on:bool) -> void:
	if toggled_on: parent.context_menu.show(parent.name)


func _on_drag_button_button_down() -> void:
	is_dragging = true
	var list = parent.get_parent()
	if list is not ReorderableContainer: return
	list._focus_child = parent
	list._is_press = true


func _on_drag_button_button_up() -> void:
	is_dragging = false
	var list = parent.get_parent()
	if list is not ReorderableContainer: return
	list._is_press = false
