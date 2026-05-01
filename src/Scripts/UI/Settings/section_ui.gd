extends Control

const section:String = 'ui'


func _ready() -> void:
	%'UI Fold'.folded = self.section in SessionManager.folded_sections
	var image_detail = SessionManager.image_detail_values.find_key(SessionManager.image_detail)
	if image_detail == null: image_detail = 0
	print(SessionManager.image_detail)
	print(image_detail)
	%'Image Detail'.set_value_no_signal(image_detail)


func _on_ui_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && self.section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(self.section)
	else:
		SessionManager.folded_sections.erase(self.section)


func _on_image_detail_value_changed(value:float) -> void:
	SessionManager.image_detail = SessionManager.image_detail_values[int(value)]
