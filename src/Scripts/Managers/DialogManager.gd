extends Node

const console_scene:PackedScene = preload('res://Scenes/Console/Console.tscn')

@onready var confirmation_dialog_scene:PackedScene = SessionManager.get_scene('Modals/Confirmation/scene')
@onready var select_file_scene:PackedScene = SessionManager.get_scene('Modals/Select File/scene')
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
	popup.set('visible', true)


func popup_console() -> void:
	var popup:Window = console_scene.instantiate()
	SessionManager.add_child(popup)
	popup.show()


func popup_confirmation_dialog(text:String, subtext:String, confirm_callback:Callable, denied_callback=null) -> void:
	var popup:Node = confirmation_dialog_scene.instantiate()
	popup.text = text
	popup.subtext = subtext
	popup_custom(popup, confirm_callback, denied_callback)


func popup_file_select(title:String, filters:PackedStringArray, confirm_callback:Callable, denied_callback=null) -> void:
	var popup:Node = select_file_scene.instantiate()
	var popup_:Node = popup.get_node('%popup')
	popup_.title = title
	popup_.filters = filters
	popup_custom(popup, confirm_callback, denied_callback)


func popup_image_select(confirm_callback:Callable, denied_callback=null, title:String='Select Image') -> void:
	DialogManager.popup_file_select(title, ['*.png','*.jpg','*.jpeg','*.webp','*.svg'], func(data:Dictionary) -> void:
		var path:String = data.get('path')
		var ext:String = path.get_extension().to_lower()
		var file := FileAccess.open(path, FileAccess.READ)
		if not file: return

		var image := Image.load_from_file(path)
		var texture := ImageTexture.create_from_image(image)

		confirm_callback.call({
			'path': path,
			'type': ext,
			'texture': texture,
		})
	,denied_callback)
