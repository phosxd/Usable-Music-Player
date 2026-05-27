extends Control

signal selected

enum CardMode {
	detailed,
	minimal,
}

@onready var context_menu:ContextMenu = SessionManager.context_menus.track_card
@onready var card_details_scene:PackedScene = SessionManager.get_scene('Tracks/card_details')
var track: DBTrack
var selected_mode := CardMode.detailed
var card_details_instance: Control
var details_reserved:bool = false


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track:
		self.queue_free()
		return


func set_mode(mode:int) -> void:
	self.selected_mode = mode as CardMode
	if card_details_instance: card_details_instance.set_mode(mode)


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
		card_details_instance.get_node('%Options').button_pressed = true


func _on_control_on_screen_activated() -> void:
	if details_reserved: return
	details_reserved = true
	Async.create_thread(_on_control_on_screen_activated_2.bind(%Button))


func _on_control_on_screen_activated_2(button:Button) -> void:
	if card_details_instance: return
	card_details_instance = card_details_scene.instantiate()
	card_details_instance.init(self, self.track, button)
	self.add_child.call_deferred(card_details_instance)


func _on_control_on_screen_deactivated() -> void:
	if card_details_instance:
		if not card_details_instance.initialized:
			await card_details_instance.init_completed
		card_details_instance.queue_free()
		details_reserved = false
