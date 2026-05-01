extends Node

const confirmation_dialog_scene:PackedScene = preload('res://Scenes/Dialogs/Confirmation/scene.tscn')
const shadow_color := Color(0,0,0,0.5)


func popup_confirmation_dialog(text:String, subtext:String, confirm_callback:Callable, denied_callback=null) -> void:
	var shadow := ColorRect.new()
	shadow.color = shadow_color
	SessionManager.main_scene.add_child(shadow)
	shadow.size = SessionManager.main_scene.size
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)

	var popup:Control = confirmation_dialog_scene.instantiate()
	popup.text = text
	popup.subtext = subtext
	popup.confirmed.connect(func() -> void:
		if confirm_callback is Callable: confirm_callback.call()
		popup.queue_free()
		shadow.queue_free()
	)
	popup.denied.connect(func() -> void:
		if denied_callback is Callable: denied_callback.call()
		popup.queue_free()
		shadow.queue_free()
	)
	SessionManager.main_scene.add_child(popup)
