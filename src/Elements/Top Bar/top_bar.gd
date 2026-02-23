extends Control


func _on_search_text_submitted(new_text:String) -> void:
	SessionManager.search_term = new_text


func _on_search_text_changed(new_text:String) -> void:
	if new_text.is_empty():
		%Search.text_submitted.emit('')
