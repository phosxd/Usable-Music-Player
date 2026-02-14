extends Control

@onready var default_player_shadow_style:StyleBox = %'Player Shadow'.get_theme_stylebox('panel')
@onready var tabs:Dictionary[String,Array] = {
	'settings': [%'Tab Button Settings', preload('res://Scenes/Tabs/Settings/settings.tscn')],
	'artists': [%'Tab Button Artists', preload('res://Scenes/Tabs/Artists/artists.tscn')],
	'albums': [%'Tab Button Albums', preload('res://Scenes/Tabs/Albums/albums.tscn')],
	'tracks': [%'Tab Button Tracks', preload('res://Scenes/Tabs/Tracks/tracks.tscn')],
	'.full_screen_player': [%'Tab Button Full Screen Player', preload('res://Scenes/Tabs/Full Screen Player/full_screen_player.tscn')]
}
var tab_history:Array[String] = []


func _ready() -> void:
	set_tab('albums')
	PlayerManager.current_track_updated.connect(update_current_track)
	update_current_track(PlayerManager.queue_position)


func update_current_track(track_queue_position:int) -> void:
	var current_track = PlayerManager.queue[track_queue_position]
	if not current_track.album.cover == %'Currently Playing Track Cover'.texture:
		%'Currently Playing Track Cover'.texture = current_track.album.cover

		var dominant_color:Color = current_track.album.get_album_dominant_color()
		var tinted_dominant_color:Color = dominant_color.lerp(Color.WHITE, 0.75)
		var dark_tinted_dominant_color:Color = dominant_color.lerp(Color.WHITE, 0.55)
		var new_style = default_player_shadow_style.duplicate()
		new_style.shadow_color = Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.4)
		%'Player Shadow'.remove_theme_stylebox_override('panel')
		%'Player Shadow'.add_theme_stylebox_override('panel', new_style)

		var global_theme := ThemeDB.get_project_theme()
		global_theme.set_color('icon_normal_color', 'Button', dark_tinted_dominant_color)
		global_theme.set_color('icon_hover_color', 'Button', dark_tinted_dominant_color)
		global_theme.set_color('icon_pressed_color', 'Button', tinted_dominant_color)
		global_theme.set_color('icon_hover_pressed_color', 'Button', tinted_dominant_color)
		var new_slider_style:StyleBoxFlat = global_theme.get_stylebox('grabber_area', 'HSlider').duplicate()
		new_slider_style.bg_color = dark_tinted_dominant_color
		global_theme.set_stylebox('grabber_area', 'HSlider', new_slider_style)
		global_theme.set_stylebox('grabber_area_highlight', 'HSlider', new_slider_style)


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
	if not tab.begins_with('.'): clear_tab_history()
	set_tab(tab)


func _on_page_back_pressed() -> void:
	pop_tab_history()
