extends Control

signal selected

@onready var card_details_scene:PackedScene = SessionManager.get_scene('Modals/Select Tracks/track_card_details')

var track: DBTrack

var card_details_instance: Control
var details_reserved:bool = false
var button_pressed:bool = false


func init(track_:DBTrack) -> void:
	track = track_
	if not track:
		queue_free()
		return


func _on_button_toggled(toggled_on:bool) -> void:
	button_pressed = toggled_on
	selected.emit()


func _on_control_on_screen_activated() -> void:
	if details_reserved: return
	details_reserved = true
	Async.create_thread(_on_control_on_screen_activated_2.bind(%Button))


func _on_control_on_screen_activated_2(button:Button) -> void:
	if card_details_instance: return
	card_details_instance = card_details_scene.instantiate()
	if not button: return
	card_details_instance.init(self, track, button)
	if not self: return
	add_child.call_deferred(card_details_instance)


func _on_control_on_screen_deactivated() -> void:
	if card_details_instance:
		if not card_details_instance.initialized:
			await card_details_instance.init_completed
		card_details_instance.queue_free()
		details_reserved = false
