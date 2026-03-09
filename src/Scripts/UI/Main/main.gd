extends Control

const overlay_color := Color(0.25, 0.25, 0.25, 0.5)
const console_scene := preload('res://Scenes/Console/Console.tscn')

@onready var general_options_popup:PopupMenu = %'General Options'.get_popup()
@onready var tabs:Dictionary[String,Array] = {
	'settings': [%'Tab Button Settings', SessionManager.get_layout_theme_scene('settings')],
	'artists': [%'Tab Button Artists', SessionManager.get_layout_theme_scene('artists')],
	'artist_page': [null, SessionManager.get_layout_theme_scene('artist_page')],
	'albums': [%'Tab Button Albums', SessionManager.get_layout_theme_scene('albums')],
	'album_page': [null, SessionManager.get_layout_theme_scene('album_page')],
	'tracks': [%'Tab Button Tracks', SessionManager.get_layout_theme_scene('tracks')],
	'genres': [%'Tab Button Genres', SessionManager.get_layout_theme_scene('genres')],
	'genre_page': [null, SessionManager.get_layout_theme_scene('genre_page')],
	'.immersive_player': [%'Tab Button Immersive Player', SessionManager.get_layout_theme_scene('immersive player')]
}
@onready var indexing_label_template:String = %'Indexing Label'.text
var tab_history:Array[Array] = []

var album_dominant_color: Color


func _ready() -> void:
	SessionManager.main_scene = self
	var default_tab:String = SessionManager.landing_page
	if default_tab.is_empty(): default_tab = SessionManager.last_tab
	set_tab(default_tab)
	PlayerManager.current_track_updated.connect(update_current_track)
	SessionManager.value_changed.connect(func(property_name:String) -> void:
		if property_name == 'visualizer_mode':
			%Player.update_visualizer(album_dominant_color)
		if property_name == 'dynamic_accents':
			update_accents()
			%Player.update_visualizer(album_dominant_color)
	)
	update_current_track(0, PlayerManager.get_current_track())
	update_accents()
	%Player.update_visualizer(album_dominant_color)

	general_options_popup.id_pressed.connect(_on_general_options_id_pressed)


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
	
	#var track = PlayerManager.get_current_track()
	#var dominant_color = track.album.get_album_dominant_color()
	#var dominant_colors = [
		#dominant_color,
		#track.album.palette.get('secondary', Color.WHITE),
		#track.album.palette.get('trinary', Color.WHITE),
		#track.album.palette.get('blend_full', Color.WHITE),
	#]
	#dominant_colors.shuffle()
	#var mat = %'Background'.material
	#var index:int = -1
	#for i in ['topright','topleft','bottomright','bottomleft']:
		#index += 1
		#mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if track == null: return
	var old_cover = %'Current Track Cover'.texture
	track.album.get_cover_threaded(func(cover) -> void:
		%'Current Track Cover'.texture = cover
	)
	if old_cover != %'Current Track Cover'.texture:
		update_accents()
		%Player.update_visualizer(album_dominant_color)


func set_tab(tab:String, data=null) -> void:
	SessionManager.last_tab = tab
	tab_history.append([tab, data])

	# Remove tab content.
	%'Tab Content/_label'.hide()
	for child in %'Tab Content'.get_children():
		if child.name.begins_with('_'): continue
		child.queue_free()

	# Find matching tab.
	for tab_:String in tabs:
		var tab_button = tabs[tab_].get(0)
		var tab_scene:PackedScene = tabs[tab_].get(1)
		# If matching tab, add scene & append history.
		if tab_ == tab:
			if tab_button: tab_button.button_pressed = true
			if tab_scene is PackedScene:
				var scene = tab_scene.instantiate()
				if scene.has_method('init'):
					if data != null: scene.call('init', data)
					else: scene.call('init')
				_parse_tab_config(scene)
				%'Tab Content'.add_child(scene)
				
		# If not matching, depress button.
		elif tab_button:
			tab_button.button_pressed = false

	if tab.is_empty():
		%'Tab Content/_label'.show()


func _parse_tab_config(scene:Node) -> void:
	if not %Search or not %'Sort Mode' or not %'Ascend Mode': return
	var tab_config = scene.get('tab_config')
	if tab_config is Dictionary:
		var sort_mode_config = tab_config.get('sort_mode',{})
		var ascend_mode_config = tab_config.get('ascend_mode',{})
		var search_config = tab_config.get('search',{})

		# Sort mode config.
		if sort_mode_config is Dictionary:
			%'Sort Mode'.disabled = not sort_mode_config.get('enabled', false)
			# Add options.
			%'Sort Mode'.clear()
			for item:String in sort_mode_config.get('options',[]):
				%'Sort Mode'.add_item(item)
			if %'Sort Mode'.item_count == 0:
				%'Sort Mode'.add_item('Sort by: Title')
			# Set default.
			var sort_mode_default = sort_mode_config.get('default')
			if sort_mode_default is String:
				var default = SessionManager.get(sort_mode_default)
				if default != null: %'Sort Mode'.selected = default
			# Connect callback.
			var sort_mode_callback = sort_mode_config.get('callback')
			if sort_mode_callback is Callable:
				%'Sort Mode'.item_selected.connect(sort_mode_callback)

		# Ascend mode config.
		if ascend_mode_config is Dictionary:
			%'Ascend Mode'.disabled = not ascend_mode_config.get('enabled', false)
			# Set default.
			var ascend_mode_default = ascend_mode_config.get('default')
			if ascend_mode_default is String:
				var default = SessionManager.get(ascend_mode_default)
				if default is bool: %'Ascend Mode'.selected = int(default)
			# Connect callback.
			var ascend_mode_callback = ascend_mode_config.get('callback')
			if ascend_mode_callback is Callable:
				%'Ascend Mode'.item_selected.connect(ascend_mode_callback)

		# Ascend mode config.
		if search_config is Dictionary:
			%'Search'.editable = search_config.get('enabled', false)
			# Set default.
			var search_default = search_config.get('default')
			if search_default is String:
				%'Search'.text = search_default
			# Connect callback.
			var search_callback = search_config.get('callback')
			if search_callback is Callable:
				%'Search'.text_submitted.connect(search_callback)


func refresh_tab() -> void:
	var last_tab = tab_history.get(tab_history.size()-1)
	tab_history.pop_back()
	set_tab(last_tab[0], last_tab[1])


func go_back() -> void:
	tab_history.pop_back()
	var last_tab = tab_history.pop_back()
	if last_tab is not Array:
		set_tab('')
		return
	set_tab(last_tab[0], last_tab[1])


func _on_general_options_id_pressed(id:int) -> void:
	match id:
		0: set_tab('settings')
		1:
			var popup:Window = console_scene.instantiate()
			add_child(popup)
			popup.show()


func _on_tab_button_pressed(tab:String) -> void:
	set_tab(tab)


func _on_back_button_pressed() -> void:
	go_back()
