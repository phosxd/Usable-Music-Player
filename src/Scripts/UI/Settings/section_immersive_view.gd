extends Control

const section:String = 'Immersive View'


func _ready() -> void:
	%'Immersive View Slide Away Player'.set_pressed_no_signal(SessionManager.immersive_view_slide_away_player)
	%'Immersive View Reactive Background'.set_pressed_no_signal(SessionManager.immersive_view_reactive_background)
	%'Immersive View Fold'.folded = section in SessionManager.folded_sections
	for texture_name:String in SessionManager.immersive_view_texture_names:
		%'Immersive View Texture Name'.add_item(texture_name)
	var selected:int = SessionManager.immersive_view_texture_names.find(SessionManager.immersive_view_texture_name)
	%'Immersive View Texture Name'.selected = selected+1 if selected != -1 else 0


func _on_immersive_view_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(section)
	else:
		SessionManager.folded_sections.erase(section)


func _on_immersive_view_texture_name_item_selected(index:int) -> void:
	if index == 0:
		SessionManager.immersive_view_texture_name = ''
	else:
		SessionManager.immersive_view_texture_name = SessionManager.immersive_view_texture_names[index-1]


func _on_slide_away_player_toggled(toggled_on:bool) -> void:
	SessionManager.immersive_view_slide_away_player = toggled_on


func _on_immersive_view_reactive_background_toggled(toggled_on:bool) -> void:
	SessionManager.immersive_view_reactive_background = toggled_on
