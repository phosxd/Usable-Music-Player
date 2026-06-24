extends Control

signal pressed

@onready var context_menu:ContextMenu = SessionManager.context_menus.playlist_card
var is_dragging:bool = false
var playlist: DBPlaylist


func _ready() -> void:
	context_menu.id_pressed.connect(_context_menu_id_pressed)


func init(playlist_:DBPlaylist) -> void:
	playlist = playlist_
	if not playlist:
		queue_free()
		return
	update_data()
	playlist.saved.connect(_on_playlist_saved)
	playlist.removed.connect(_on_playlist_removed)


func update_data() -> void:
	%Name.text = playlist.id
	#%'Track Count'.text = str(playlist.track_ids.size())
	#%Image.texture = playlist.get_cover()
	%Button.tooltip_text = playlist.id


func _on_playlist_saved() -> void:
	update_data()


func _on_playlist_removed() -> void:
	queue_free()


func _on_button_pressed() -> void:
	pressed.emit()


func _on_move_up_pressed() -> void:
	get_parent().move_child(self, get_index()-1)


func _on_move_down_pressed() -> void:
	get_parent().move_child(self, get_index()+1)


func _on_drag_button_button_down() -> void:
	is_dragging = true
	var list = get_parent()
	if list is not ReorderableContainer: return
	list._focus_child = self
	list._is_press = true


func _on_drag_button_button_up() -> void:
	is_dragging = false
	var list = get_parent()
	if list is not ReorderableContainer: return
	list._is_press = false


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		context_menu.show(name)


func _context_menu_id_pressed(id:String):
	if context_menu.current_instance_id != name: return
	match id:
		'play':
			var tracks:Array[DBTrack] = playlist.get_tracks()
			if tracks.size() > 0: PlayerManager.set_queue_and_track(tracks, tracks[0])
