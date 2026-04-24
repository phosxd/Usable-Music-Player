extends Control

@export var bg_color := Color(0.18, 0.18, 0.18, 1.0):
	set(value):
		bg_color = value
		%Background.color = value

@export var global_margin:Array = [0,0,0,0]:
	set(value):
		global_margin = value
		var i:int = 0
		for property:String in ['left','top','right','bottom']:
			%'Global Margin'.add_theme_constant_override('margin_'+property, value[i])
			i += 1

@export var tools_margin:Array = [0,0,0,0]:
	set(value):
		tools_margin = value
		var i:int = 0
		for property:String in ['left','top','right','bottom']:
			%'Tools Margin'.add_theme_constant_override('margin_'+property, value[i])
			i += 1

@export var sidebar_margin:Array = [0,0,0,0]:
	set(value):
		sidebar_margin = value
		var i:int = 0
		for property:String in ['left','top','right','bottom']:
			%'Sidebar Margin'.add_theme_constant_override('margin_'+property, value[i])
			i += 1

@export var right_sidebar_margin:Array = [0,0,0,0]:
	set(value):
		right_sidebar_margin = value
		var i:int = 0
		for property:String in ['left','top','right','bottom']:
			%'Right Sidebar Margin'.add_theme_constant_override('margin_'+property, value[i])
			i += 1

@export var search_margin:Array = [0,0,0,0]:
	set(value):
		search_margin = value
		var i:int = 0
		for property:String in ['left','top','right','bottom']:
			%'Search Margin'.add_theme_constant_override('margin_'+property, value[i])
			i += 1

@onready var tabs:Dictionary[String,Array] = {
	'settings': [%'Tab Button Settings', SessionManager.get_layout_theme_scene('Settings/tab')],
	'artists': [%'Tab Button Artists', SessionManager.get_layout_theme_scene('Artists/tab')],
	'artist_page': [null, SessionManager.get_layout_theme_scene('Artist Page/page')],
	'albums': [%'Tab Button Albums', SessionManager.get_layout_theme_scene('Albums/tab')],
	'album_page': [null, SessionManager.get_layout_theme_scene('Album Page/page')],
	'tracks': [%'Tab Button Tracks', SessionManager.get_layout_theme_scene('Tracks/tab')],
	'genres': [%'Tab Button Genres', SessionManager.get_layout_theme_scene('Genres/tab')],
	'genre_page': [null, SessionManager.get_layout_theme_scene('Genre Page/page')],
	'.immersive_player': [%'Tab Button Immersive Player', SessionManager.get_layout_theme_scene('Immersive Player/tab')]
}
var tab_history:Array[Array] = []

var album_dominant_color: Color
var ascend_mode:bool = true


func _ready() -> void:
	SessionManager.main_scene = self
	var default_tab:String = SessionManager.landing_page
	if default_tab.is_empty(): default_tab = SessionManager.last_tab
	set_tab(default_tab)
	PlayerManager.current_track_updated.connect(update_current_track)
	SessionManager.value_changed.connect(func(property:String) -> void:
		if property == 'visualizer_mode':
			%Player.update_visualizer(ThemeManager.accent)
		if property in ['dynamic_accents','custom_accent_enabled','custom_accent']:
			update_accents()
			%Player.update_visualizer(ThemeManager.accent)
		if property == 'tab_content_split':
			%'Tab Content Split'.split_offsets = SessionManager.tab_content_split
		if property == 'right_sidebar_tab':
			%'Tab Content Split'.collapsed = SessionManager.right_sidebar_tab == ''
	)
	update_current_track(0, PlayerManager.get_current_track())
	update_accents()
	%Player.update_visualizer(ThemeManager.accent)
	%'Tab Content Split'.split_offsets = SessionManager.tab_content_split
	%'Tab Content Split'.collapsed = SessionManager.right_sidebar_tab == ''

	%'Right Sidebar Margin'.add_child(SessionManager.get_layout_theme_scene('Queue/queue').instantiate())
	%'Right Sidebar Margin'.add_child(SessionManager.get_layout_theme_scene('Lyrics/lyrics').instantiate())


func update_accents() -> void:
	var prev_album_dominant_color:Color = album_dominant_color
	if SessionManager.dynamic_accents:
		if not PlayerManager.queue.is_empty():
			album_dominant_color = PlayerManager.queue[PlayerManager.queue_position].album.get_album_dominant_color()
	elif SessionManager.custom_accent_enabled:
		album_dominant_color = SessionManager.custom_accent
	# If dynamic & custom accents are disabled, use OS accent color.
	else:
		album_dominant_color = DisplayServer.get_accent_color()
	if prev_album_dominant_color == album_dominant_color: return

	var accent:Color = album_dominant_color
	# Clamp colors based on theme luminance.
	var luminance:float = ThemeManager.bg_color.get_luminance() if ThemeManager.bg_color.a != 0 else ThemeManager.default_bg_color.get_luminance()
	if luminance < 0.5:
		accent.v = max(0.6, accent.v)
	ThemeManager.accent = accent


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if track == null: return
	var old_cover = %'Current Track Cover'.texture
	track.album.get_cover_threaded(func(cover) -> void:
		%'Current Track Cover'.texture = cover
	)
	if old_cover != %'Current Track Cover'.texture:
		update_accents()
		%Player.update_visualizer(ThemeManager.accent)


func set_tab(tab:String, data=null) -> void:
	SessionManager.last_tab = tab
	tab_history.append([tab, data])

	# Remove tab content.
	%'Tab Content/_label'.hide()
	for child in %'Tab Content'.get_children():
		if child.name.begins_with('_') or child.name == 'Topbar': continue
		if child.process_mode == Node.PROCESS_MODE_DISABLED: continue
		if child.has_method('unload'):
			child.process_mode = Node.PROCESS_MODE_DISABLED
			child.hide()
			child.call('unload')
		else:
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
		var play_config = tab_config.get('play',{})
		var shuffle_config = tab_config.get('shuffle',{})
		var sort_mode_config = tab_config.get('sort_mode',{})
		var ascend_mode_config = tab_config.get('ascend_mode',{})
		var search_config = tab_config.get('search',{})

		# Play config.
		if play_config is Dictionary:
			%'Play All'.disabled = not play_config.get('enabled', false)
			var play_callback = play_config.get('callback')
			if play_callback is Callable:
				%'Play All'.pressed.connect(play_callback)

		# Shuffle config.
		if shuffle_config is Dictionary:
			%'Shuffle All'.disabled = not shuffle_config.get('enabled', false)
			var shuffle_callback = shuffle_config.get('callback')
			if shuffle_callback is Callable:
				%'Shuffle All'.pressed.connect(shuffle_callback)

		# Sort mode config.
		if sort_mode_config is Dictionary:
			%'Sort Mode'.disabled = not sort_mode_config.get('enabled', false)
			# Add options.
			%'Sort Mode'.clear()
			for item:String in sort_mode_config.get('options',[]):
				%'Sort Mode'.add_item(item)
			if %'Sort Mode'.item_count == 0:
				%'Sort Mode'.add_item('Title')
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
				if default is bool: ascend_mode = not default
			_on_ascend_mode_pressed() # Update state & text.
			# Connect callback.
			var ascend_mode_callback = ascend_mode_config.get('callback')
			if ascend_mode_callback is Callable:
				%'Ascend Mode'.pressed.connect(func() -> void:
					if not ascend_mode_callback.get_object(): return
					ascend_mode_callback.call(ascend_mode)
				)

		# Search config.
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


func _on_tab_button_pressed(tab:String) -> void:
	set_tab(tab)


func _on_back_button_pressed() -> void:
	go_back()


func _on_ascend_mode_pressed() -> void:
	ascend_mode = not ascend_mode
	%'Ascend Mode'.text = 'A-Z' if ascend_mode else 'Z-A'


func _on_favorites_toggled(toggled_on:bool) -> void:
	%'Favorites Options'.visible = toggled_on


func _on_tab_content_split_drag_ended() -> void:
	SessionManager.tab_content_split = %'Tab Content Split'.split_offsets
