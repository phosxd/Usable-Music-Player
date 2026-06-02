extends Control

const section:String = 'Keybinds'


func _ready() -> void:
	%'Keybinds Fold'.folded = section in SessionManager.get_var('folded_sections')
	%'Play Pause Key'.text = SessionManager.get_var('keybind_play_pause')
	%'Volume Up Key'.text = SessionManager.get_var('keybind_volume_up')
	%'Volume Down Key'.text = SessionManager.get_var('keybind_volume_down')
	%'Skip Backward Key'.text = SessionManager.get_var('keybind_skip_backward')
	%'Skip Forward Key'.text = SessionManager.get_var('keybind_skip_forward')
	%'Page Backward Key'.text = SessionManager.get_var('keybind_page_backward')
	%'Page Forward Key'.text = SessionManager.get_var('keybind_page_forward')
	%'Toggle ImView Key'.text = SessionManager.get_var('keybind_toggle_imview')


func _on_folding_changed(is_folded: bool) -> void:
	if is_folded && section not in SessionManager.get_var('folded_sections'):
		SessionManager.get_var('folded_sections').append(section)
	else:
		SessionManager.get_var('folded_sections').erase(section)


func _on_play_pause_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_play_pause', text_keycode)


func _on_skip_backward_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_skip_backward', text_keycode)


func _on_skip_forward_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_skip_forward', text_keycode)


func _on_volume_up_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_volume_up', text_keycode)


func _on_volume_down_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_volume_down', text_keycode)


func _on_page_backward_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_page_backward', text_keycode)


func _on_page_forward_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_page_forward', text_keycode)


func _on_toggle_imview_key_keycode_changed(text_keycode:String) -> void:
	SessionManager.set_var('keybind_toggle_imview', text_keycode)
