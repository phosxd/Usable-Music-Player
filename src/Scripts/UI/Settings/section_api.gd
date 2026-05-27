extends Control

const section:String = 'API'


func _ready() -> void:
	%'API Fold'.folded = section in SessionManager.get_var('folded_sections')


func _on_api_fold_folding_changed(is_folded: bool) -> void:
	if is_folded && section not in SessionManager.get_var('folded_sections'):
		SessionManager.get_var('folded_sections').append(section)
	else:
		SessionManager.get_var('folded_sections').erase(section)
