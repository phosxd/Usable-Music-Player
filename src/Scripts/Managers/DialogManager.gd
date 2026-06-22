extends Node

const console_scene:PackedScene = preload('res://Scenes/Console/Console.tscn')

@onready var confirmation_dialog_scene:PackedScene = SessionManager.get_scene('Modals/Confirmation/scene')
@onready var create_playlist_scene:PackedScene = SessionManager.get_scene('Modals/Create Playlist/scene')
@onready var select_tracks_scene:PackedScene = SessionManager.get_scene('Modals/Select Tracks/scene')

const shadow_color := Color(0,0,0,0.5)


func popup_custom(popup:Node, confirm_callback:Callable, denied_callback=null) -> void:
	var shadow := ColorRect.new()
	shadow.color = shadow_color
	SessionManager.main_scene.add_child(shadow)
	shadow.size = SessionManager.main_scene.size
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)

	if popup.has_signal('confirmed'):
		popup.confirmed.connect(func(...args) -> void:
			if confirm_callback is Callable: confirm_callback.callv(args)
			popup.queue_free()
			shadow.queue_free()
		)
	if popup.has_signal('denied'):
		popup.denied.connect(func(...args) -> void:
			if denied_callback is Callable: denied_callback.callv(args)
			popup.queue_free()
			shadow.queue_free()
		)
	SessionManager.main_scene.add_child(popup)


func popup_console() -> void:
	var popup:Window = console_scene.instantiate()
	SessionManager.add_child(popup)
	popup.show()


func popup_confirmation_dialog(text:String, subtext:String, confirm_callback:Callable, denied_callback=null) -> void:
	var popup:Control = confirmation_dialog_scene.instantiate()
	popup.text = text
	popup.subtext = subtext
	popup_custom(popup, confirm_callback, denied_callback)
