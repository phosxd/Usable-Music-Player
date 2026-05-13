extends Control

@onready var context_menu:ContextMenu = SessionManager.context_menus.queue_card
var is_dragging:bool = false


func _ready() -> void:
	context_menu.id_pressed.connect(_context_menu_id_pressed)
	highlight(false)


func init(track:DBTrack) -> void:
	%Name.text = track.name
	%Artist.text = track.album.artist.name
	%Length.text = DBTrack.get_track_position_formatted(track.length)
	%Image.texture = track.album.get_cover()
	%Button.tooltip_text = track.name


func highlight(on:bool) -> void:
	%Button.set_pressed_no_signal(on)
	if on:
		%Name.self_modulate = Color.WHITE
		%Artist.self_modulate = Color.WHITE
	else:
		var color := Color(1,1,1, 0.75)
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


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		context_menu.show(name)


func _context_menu_id_pressed(id:String):
	if context_menu.current_instance_id != name: return
	var track:DBTrack = PlayerManager.queue[self.get_index()]
	if id in ['remove','remove_track']:
		PlayerManager.remove_from_queue(track)
	match id:
		'remove_album':
			for queued_track:DBTrack in PlayerManager.queue.duplicate():
				if track.album == queued_track.album:
					PlayerManager.remove_from_queue(queued_track)
		'remove_artist':
			for queued_track:DBTrack in PlayerManager.queue.duplicate():
				if track.album.artist == queued_track.album.artist:
					PlayerManager.remove_from_queue(queued_track)
		'stop_after_this':
			PlayerManager.stop_at_index = PlayerManager.queue.find(track)+1
		'show_album':
			SessionManager.main_scene.set_tab('album_page', track.album)
		'show_in_files':
			OS.shell_show_in_file_manager(track.get_full_path())
