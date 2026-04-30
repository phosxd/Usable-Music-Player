extends PanelContainer

signal selected

enum CardMode {
	detailed,
	minimal,
}

@onready var context_menu:ContextMenu = SessionManager.context_menus.track_card
@onready var card_details_scene:PackedScene = SessionManager.get_layout_theme_scene('Tracks/card_details')
var track: DBTrack
var selected_mode := CardMode.detailed
var card_details_instance: Control


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track:
		self.queue_free()
		return


func set_mode(mode:int) -> void:
	self.selected_mode = mode as CardMode
	if card_details_instance: card_details_instance.set_mode(mode)


func _on_button_pressed() -> void:
	PlayerManager.auto_queue_start_index = -1
	selected.emit()


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		card_details_instance.get_node('%Options').button_pressed = true


func _on_control_on_screen_activated() -> void:
	if card_details_instance: return
	card_details_instance = card_details_scene.instantiate()
	card_details_instance.init(self, self.track)
	self.add_child(card_details_instance)


func _on_control_on_screen_deactivated() -> void:
	if card_details_instance: card_details_instance.queue_free()
