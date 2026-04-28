extends Control

const section:String = 'ui'


func _ready() -> void:
	%'UI Fold'.folded = self.section in SessionManager.folded_sections


func _on_ui_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && self.section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(self.section)
	else:
		SessionManager.folded_sections.erase(self.section)
