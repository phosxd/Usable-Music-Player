extends Control

@onready var activity_menu_scene:PackedScene = SessionManager.get_layout_theme_scene('Main/activity_menu')
var activity_menu: Control


func _process(_delta:float) -> void:
	if Engine.get_process_frames() % 5 != 0: return

	var activities:int = 0
	for library:DBLibrary in LibraryManager.libraries:
		if library.currently_updating:
			activities += 1
	%Activity.text = str(activities) if activities > 0 else ''


func _on_search_text_changed(new_text:String) -> void:
	SessionManager.search_term = new_text
	%Search.text_submitted.emit(new_text)


func _on_activity_toggled(toggled_on:bool) -> void:
	if toggled_on:
		activity_menu = activity_menu_scene.instantiate()
		get_window().add_child(activity_menu)
		activity_menu.position = %Activity.global_position+Vector2(0,%Activity.size.y)
	else:
		if activity_menu: activity_menu.queue_free()
