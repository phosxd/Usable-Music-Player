extends Control

const section:String = 'UI'


func _ready() -> void:
	%'UI Fold'.folded = self.section in SessionManager.get_var('folded_sections')
	var image_detail = SessionManager.get_var('image_detail_values').find_key(SessionManager.get_var('image_detail'))
	if image_detail == null: image_detail = 0
	%'Image Detail'.set_value_no_signal(image_detail)
	%'Clear Queue Warning'.set_pressed_no_signal(SessionManager.get_var('clear_queue_warning'))


func _on_ui_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && section not in SessionManager.get_var('folded_sections'):
		SessionManager.get_var('folded_sections').append(section)
	else:
		SessionManager.get_var('folded_sections').erase(section)


func _on_image_detail_value_changed(value:float) -> void:
	SessionManager.set_var('image_detail', SessionManager.get_var('image_detail_values')[int(value)])


func _on_clear_queue_warning_toggled(toggled_on:bool) -> void:
	SessionManager.set_var('clear_queue_warning', toggled_on)
