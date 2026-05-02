extends Control

const section:String = 'API'


func _ready() -> void:
	%'API Fold'.folded = section in SessionManager.folded_sections


func _on_api_fold_folding_changed(is_folded: bool) -> void:
	if is_folded && section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(section)
	else:
		SessionManager.folded_sections.erase(section)
