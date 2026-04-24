extends Control


func _on_search_text_changed(new_text:String) -> void:
	SessionManager.search_term = new_text
	%Search.text_submitted.emit(new_text)
