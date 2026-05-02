extends Control

const section:String = 'UI'


func _ready() -> void:
	%'UI Fold'.folded = self.section in SessionManager.folded_sections
	var image_detail = SessionManager.image_detail_values.find_key(SessionManager.image_detail)
	if image_detail == null: image_detail = 0
	%'Image Detail'.set_value_no_signal(image_detail)
	%'Clear Queue Warning'.set_pressed_no_signal(SessionManager.clear_queue_warning)


func _on_ui_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(section)
	else:
		SessionManager.folded_sections.erase(section)


func _on_image_detail_value_changed(value:float) -> void:
	SessionManager.image_detail = SessionManager.image_detail_values[int(value)]


func _on_clear_queue_warning_toggled(toggled_on:bool) -> void:
	SessionManager.clear_queue_warning = toggled_on
