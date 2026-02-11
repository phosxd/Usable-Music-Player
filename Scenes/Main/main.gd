extends Control

@onready var tabs:Dictionary[String,Array] = {
	'settings': [%'Tab Button Settings', preload('res://Scenes/Tabs/Settings/settings.tscn')],
	'artists': [%'Tab Button Artists', preload('res://Scenes/Tabs/Artists/artists.tscn')],
	'albums': [%'Tab Button Albums', preload('res://Scenes/Tabs/Albums/albums.tscn')],
	'tracks': [%'Tab Button Tracks', preload('res://Scenes/Tabs/Tracks/tracks.tscn')],
}


func _ready() -> void:
	LibraryManager.load_library_from_cache()


func set_tab(tab:String) -> void:
	# Remove tab content.
	%'Tab Content/_label'.hide()
	for child in %'Tab Content'.get_children():
		if child.name.begins_with('_'): continue
		child.queue_free()
	# Update buttons.
	for tab_:String in tabs:
		if tab_ == tab:
			tabs[tab][0].button_pressed = true
			if tabs[tab][1] is PackedScene:
				%'Tab Content'.add_child(tabs[tab][1].instantiate())
		else:
			tabs[tab_][0].button_pressed = false

	if tab.is_empty():
		%'Tab Content/_label'.show()


func _on_audio_finished() -> void:
	pass # Replace with function body.


func _on_tab_button_pressed(tab:String) -> void:
	if tabs[tab][0].button_pressed:
		set_tab(tab)
	else:
		set_tab('')
