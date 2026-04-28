extends Control

const section:String = 'api'


func _ready() -> void:
	%'API Fold'.folded = self.section in SessionManager.folded_sections


func _on_api_fold_folding_changed(is_folded: bool) -> void:
	if is_folded && self.section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(self.section)
	else:
		SessionManager.folded_sections.erase(self.section)
