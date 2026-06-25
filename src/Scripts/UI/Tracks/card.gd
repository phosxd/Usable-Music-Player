extends Control

signal selected

@export var context_menu_name:StringName = 'track_card'
@export var details_scene_name: StringName

var card_details_scene: PackedScene
var context_menu: ContextMenu

var track: DBTrack
var card_details_instance: Control
var details_reserved:bool = false


func _ready() -> void:
	if not context_menu_name.is_empty():
		context_menu = SessionManager.get_context_menu(context_menu_name)
		context_menu.id_pressed.connect(_on_context_menu_id_pressed)
		context_menu.opened.connect(_on_context_menu_opened)
		context_menu.closed.connect(_on_context_menu_closed)
	if not details_scene_name.is_empty():
		card_details_scene = SessionManager.get_scene(details_scene_name)


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track:
		queue_free()
		return


func _on_button_pressed() -> void:
	if PlayerManager.queue.size() > 1 && SessionManager.get_var('clear_queue_warning'):
		DialogManager.popup_confirmation_dialog(
			'Do you want to continue?\nYour queue will be cleared.', # Text.
			'Disable this warning in settings.', # Subtext.
			func() -> void:
				_on_button_pressed_2()
		)
	else: _on_button_pressed_2()


func _on_button_pressed_2() -> void:
	PlayerManager.auto_queue_start_index = -1
	selected.emit()


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		context_menu.show(name)
		if card_details_instance: card_details_instance._on_context_menu_opened.call()


func _on_context_menu_opened() -> void:
	if not card_details_instance or context_menu.current_instance_id != name: return
	if card_details_instance: card_details_instance._on_context_menu_opened.call()


func _on_context_menu_closed() -> void:
	if not card_details_instance or context_menu.current_instance_id != name: return
	card_details_instance._on_context_menu_closed.call()


func _on_context_menu_id_pressed(id:String) -> void:
	if not card_details_instance or context_menu.current_instance_id != name: return
	match id:
		'play':
			PlayerManager.auto_queue_start_index = -1
			selected.emit()
		'play_next':
			PlayerManager.add_next_in_queue_with_context(track)
		'add_to_queue':
			PlayerManager.add_to_queue_with_context(track)
		'show_album':
			SessionManager.main_scene.set_tab('album_page', track.album)
		'show_in_files':
			OS.shell_show_in_file_manager(track.get_full_path())

	if card_details_instance: card_details_instance._on_context_menu_id_pressed(id)


func _on_control_on_screen_activated() -> void:
	if details_reserved: return
	details_reserved = true
	Async.create_thread(_on_control_on_screen_activated_2.bind(%Button))


func _on_control_on_screen_activated_2(button:Button) -> void:
	if card_details_instance or not card_details_scene: return
	card_details_instance = card_details_scene.instantiate()
	card_details_instance.init(self, track, button)
	add_child.call_deferred(card_details_instance)


func _on_control_on_screen_deactivated() -> void:
	if card_details_instance:
		if not card_details_instance.initialized:
			await card_details_instance.init_completed
		card_details_instance.queue_free()
		details_reserved = false
