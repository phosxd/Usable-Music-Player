extends Control

@onready var default_player_shadow_style:StyleBox = %'Glow Visualizer'.get_theme_stylebox('panel')
@onready var tabs:Dictionary[String,Array] = {
	'settings': [%'Tab Button Settings', preload('res://Scenes/Tabs/Settings/settings.tscn')],
	'artists': [%'Tab Button Artists', preload('res://Scenes/Tabs/Artists/artists.tscn')],
	'albums': [%'Tab Button Albums', preload('res://Scenes/Tabs/Albums/albums.tscn')],
	'tracks': [%'Tab Button Tracks', preload('res://Scenes/Tabs/Tracks/tracks.tscn')],
	'genres': [%'Tab Button Genres', preload('res://Scenes/Tabs/Genres/genres.tscn')],
	'.full_screen_player': [%'Tab Button Full Screen Player', preload('res://Scenes/Tabs/Full Screen Player/full_screen_player.tscn')]
}
var tab_history:Array[String] = []

var album_dominant_color: Color


func _ready() -> void:
	SessionManager.main_scene = self
	set_tab('albums')
	PlayerManager.current_track_updated.connect(update_current_track)
	PlayerManager.track_peak_volume_changed.connect(update_visualizer)
	SessionManager.value_changed.connect(func(property_name:String) -> void:
		if property_name == 'visualizer_mode':
			update_visualizer()
		if property_name == 'dynamic_accents':
			update_accents()
			update_visualizer()
	)
	update_current_track(0, PlayerManager.get_current_track())


func update_accents() -> void:
	var prev_album_dominant_color:Color = album_dominant_color
	if SessionManager.dynamic_accents:
		if not PlayerManager.queue.is_empty():
			album_dominant_color = PlayerManager.queue[PlayerManager.queue_position].album.get_album_dominant_color()
	else:
		album_dominant_color = Color(0.75,0.75,0.75)
	if prev_album_dominant_color == album_dominant_color: return

	var tinted_dominant_color:Color = album_dominant_color.lerp(Color.WHITE, 0.75)
	var dark_tinted_dominant_color:Color = album_dominant_color.lerp(Color.WHITE, 0.4)
	var global_theme := ThemeDB.get_project_theme()
	global_theme.set_color('icon_normal_color', 'AccentButton', dark_tinted_dominant_color)
	global_theme.set_color('icon_hover_color', 'AccentButton', dark_tinted_dominant_color)
	global_theme.set_color('icon_pressed_color', 'AccentButton', tinted_dominant_color)
	global_theme.set_color('icon_hover_pressed_color', 'AccentButton', tinted_dominant_color)
	var new_slider_style:StyleBoxFlat = global_theme.get_stylebox('grabber_area', 'HSlider').duplicate()
	new_slider_style.bg_color = dark_tinted_dominant_color
	global_theme.set_stylebox('grabber_area', 'HSlider', new_slider_style)
	global_theme.set_stylebox('grabber_area_highlight', 'HSlider', new_slider_style)


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if track == null: return
	if not track.album.cover == %'Current Track Cover'.texture:
		%'Current Track Cover'.texture = track.album.cover
		%'Glow Visualizer'.add_theme_stylebox_override('panel', default_player_shadow_style.duplicate())
		update_visualizer(0)
		update_accents()


func update_visualizer(db:float=0) -> void:
	var style = %'Glow Visualizer'.get_theme_stylebox('panel')
	style.shadow_color = Color(album_dominant_color.r, album_dominant_color.g, album_dominant_color.b, 0.6)
	if SessionManager.visualizer_mode == SessionManager.VisualizerMode.OFF:
		%'Bar Visualizer'.hide()
		style.shadow_size = 25
	if SessionManager.visualizer_mode == SessionManager.VisualizerMode.GLOW:
		%'Bar Visualizer'.hide()
		style.shadow_size = 25
		var linear = db_to_linear(db)
		style.shadow_color = Color(album_dominant_color.r, album_dominant_color.g, album_dominant_color.b, MathUtils.transfer_range_of_value(Vector2(0,1), Vector2(0.6, 0.2), linear))
	elif SessionManager.visualizer_mode == SessionManager.VisualizerMode.BAR:
		%'Bar Visualizer'.show()
		style.shadow_size = 50
		style.shadow_color = Color(0,0,0, 0.25)
		%'Bar Visualizer'.color_1 = album_dominant_color

func clear_tab_history() -> void:
	tab_history.clear()


func append_tab_history(tab:String) -> void:
	tab_history.append(StringName(tab))


func pop_tab_history() -> void:
	var item = tab_history.pop_back()
	tab_history.pop_back() # Remove one tab before because it will be added later when setting the tab.
	if item is not StringName: return

	if tab_history.is_empty():
		set_tab('')
	else:
		var previous_tab = tab_history.get(tab_history.size()-1)
		if previous_tab == null: previous_tab = ''
		set_tab(String(previous_tab))


func set_tab(tab:String) -> void:
	if tab != '.full_screen_player' && tab_history.get(tab_history.size()-1) == &'.full_screen_player':
		start_fsp_reverse_anim()

	if not tab.begins_with('.'):
		tab_history.clear()

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
			if tab_ == '.full_screen_player':
				start_fsp_anim()
		# If not matching, depress button.
		elif tab_button:
			tab_button.button_pressed = false

	if tab.is_empty():
		%'Tab Content/_label'.show()
		clear_tab_history()


func _on_audio_finished() -> void:
	pass # Replace with function body.


func _on_tab_button_pressed(tab:String) -> void:
	set_tab(tab)


func _on_page_back_pressed() -> void:
	pop_tab_history()


func start_fsp_anim() -> void:
	%'Current Track Cover Container'.modulate = Color.TRANSPARENT
	%'Tab Button Full Screen Player'.disabled = true
	%'Tab Button Full Screen Player'.mouse_default_cursor_shape = CURSOR_ARROW
	%'Current Track Cover Overlay'.size = %'Current Track Cover'.size
	%'Current Track Cover Overlay'.position = %'Current Track Cover'.global_position
	%'Current Track Cover Overlay'.texture = %'Current Track Cover'.texture
	%'Current Track Cover Overlay'.show()
	var tween = %'Current Track Cover Overlay'.create_tween()
	var pos:Vector2 = %'Current Track Cover'.global_position
	tween.tween_property(%'Current Track Cover Overlay', 'position', pos, 0.0)
	tween.tween_property(%'Current Track Cover Overlay', 'position', Vector2(pos.x, pos.y+500), 0.5)
	tween.finished.connect(function.bind(tween, 1))
	tween.play()
	


func start_fsp_reverse_anim() -> void:
	%'Current Track Cover Overlay'.size = %'Current Track Cover'.size
	%'Current Track Cover Overlay'.texture = %'Current Track Cover'.texture
	%'Current Track Cover Overlay'.show()
	var tween = %'Current Track Cover Overlay'.create_tween()
	var pos:Vector2 = %'Current Track Cover'.global_position
	tween.tween_property(%'Current Track Cover Overlay', 'position', %'Current Track Cover Overlay'.position, 0.0)
	tween.tween_property(%'Current Track Cover Overlay', 'position', pos, 0.35)
	tween.finished.connect(function.bind(tween))
	tween.play()


func function(tween:Tween, mode:int=0) -> void:
	if mode == 0:
		tween.kill()
		%'Current Track Cover Container'.modulate = Color.WHITE
		%'Tab Button Full Screen Player'.disabled = false
		%'Tab Button Full Screen Player'.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	%'Current Track Cover Overlay'.hide()
