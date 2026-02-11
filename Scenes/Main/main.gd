extends Control

@onready var tabs:Dictionary[String,Array] = {
	'settings': [%'Tab Button Settings', preload('res://Scenes/Tabs/Settings/settings.tscn')],
	'artists': [%'Tab Button Artists', preload('res://Scenes/Tabs/Artists/artists.tscn')],
	'albums': [%'Tab Button Albums', preload('res://Scenes/Tabs/Albums/albums.tscn')],
	'tracks': [%'Tab Button Tracks', preload('res://Scenes/Tabs/Tracks/tracks.tscn')],
}
var tab_history:Array[String] = []


func _ready() -> void:
	LibraryManager.load_library_from_cache()


func clear_tab_history() -> void:
	tab_history.clear()
	%'Page Position'.text = ''


func append_tab_history(tab:String) -> void:
	tab_history.append(tab)
	%'Page Position'.text = ' > '.join(tab_history)


func pop_tab_history() -> void:
	var item = tab_history.pop_back()
	tab_history.pop_back() # Remove one tab before because it will be added later when setting the tab.
	if item is not String: return
	%'Page Position'.text = ' > '.join(tab_history)

	if tab_history.is_empty():
		set_tab('')
	else:
		var previous_tab = tab_history.get(-1)
		if previous_tab == null: previous_tab = ''
		set_tab(previous_tab)


func set_tab(tab:String) -> void:
	# Remove tab content.
	%'Tab Content/_label'.hide()
	for child in %'Tab Content'.get_children():
		if child.name.begins_with('_'): continue
		child.queue_free()
	# Find matching tab.
	for tab_:String in tabs:
		var tab_button = tabs[tab_].get(0)
		var tab_scene = tabs[tab_].get(1)
		# If matching tab, add scene & append history.
		if tab_ == tab:
			if tab_button: tab_button.button_pressed = true
			if tab_scene is PackedScene:
				%'Tab Content'.add_child(tab_scene.instantiate())
				append_tab_history(tab)
		# If not matching, depress button.
		elif tab_button:
			tab_button.button_pressed = false

	if tab.is_empty():
		%'Tab Content/_label'.show()
		clear_tab_history()


func _on_audio_finished() -> void:
	pass # Replace with function body.


func _on_tab_button_pressed(tab:String) -> void:
	clear_tab_history()
	if tabs[tab][0].button_pressed:
		set_tab(tab)
	else:
		set_tab('')


func _on_page_back_pressed() -> void:
	pop_tab_history()
