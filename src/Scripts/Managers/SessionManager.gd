## Manage the current session.
extends Node

const minilog_importance := MiniLog.Importance.High

## Emitted when the session has been loaded.
signal session_loaded
signal value_changed(property_name:String, source_name:String)
## Path to the session file.
const session_file_path:String = 'user://session.json'

var main_scene: Node

#region window

## The default window size.
var default_window_size: Vector2i:
	set(value):
		default_window_size = value
		value_changed.emit('default_window_size', 'base')

## The current window size.
var current_window_size: Vector2i:
	set(value):
		current_window_size = value
		value_changed.emit('current_window_size', 'base')

#endregion


var session_scripts:Dictionary[String,Object] = {}
var session_ready:bool = false
var context_menus:Dictionary[String,ContextMenu] = {}


func _ready() -> void:
	self.default_window_size = self.get_window().size
	self.current_window_size = default_window_size

	for mod:TesseractMod in TesseractAPI.mod_instances.values():
		var files:PackedStringArray = mod.get_files_at('Session Scripts')
		for file_path in files:
			var script = mod.resources[file_path]
			if script is not GDScript: continue
			init_session_script(file_path.split('/')[0].get_basename(), script)

	for file_name:String in DirAccess.get_files_at('res://Session Scripts'):
		if file_name.get_extension().to_lower() not in ['gd','gdc']: continue
		var script = load('res://Session Scripts/'+file_name)
		if script is not GDScript: continue
		init_session_script(file_name.get_basename(), script)


	load_session()
	if get_var('theme').is_empty(): set_var('theme', 'UMP_DEFAULT') # Set default layout theme if none set by session file.


	context_menus = {
		'track_card': ContextMenu.new([
			{
				'id': 'play',
				'type': 'button',
				'text': 'Play (clear queue)',
				'icon': SessionManager.get_icon('play'),
			},
			{
				'id': 'play_next',
				'type': 'button',
				'text': 'Play Next',
				'icon': SessionManager.get_icon('queue_play_next'),
			},
			{
				'id': 'add_to_queue',
				'type': 'button',
				'text': 'Add To Queue',
				'icon': SessionManager.get_icon('queue_add_to_queue'),
			},
			{
				'id': 'show_album',
				'type': 'button',
				'text': 'Show Album',
				'icon': SessionManager.get_icon('folder'),
			},
			{
				'id': 'show_in_files',
				'type': 'button',
				'text': 'Show In Files',
				'icon': SessionManager.get_icon('folder'),
			},
		]),
		'queue_card': ContextMenu.new([
			{
				'id': 'remove',
				'type': 'submenu',
				'text': 'Remove',
				'icon': SessionManager.get_icon('remove'),
				'items': [
					{
						'id': 'remove_track',
						'type': 'button',
						'text': 'Track',
					},
					{
						'id': 'remove_album',
						'type': 'button',
						'text': 'Album',
					},
					{
						'id': 'remove_artist',
						'type': 'button',
						'text': 'Artist',
					},
				],
			},
			{
				'id': 'stop_after_this',
				'type': 'button',
				'text': 'Stop After This',
				'icon': SessionManager.get_icon('pause'),
			},
			{
				'id': 'show_album',
				'type': 'button',
				'text': 'Show Album',
				'icon': SessionManager.get_icon('folder'),
			},
			{
				'id': 'show_in_files',
				'type': 'button',
				'text': 'Show In Files',
				'icon': SessionManager.get_icon('folder'),
			},
		]),
	}


	session_ready = true


func init_session_script(script_name:String, script:GDScript) -> void:
	var script_instance = script.new()
	if script_instance is not Object: return
	script_instance = script_instance as Object
	session_scripts[script_name] = script_instance


func get_var(property_name:String, source_name:String='base') -> Variant:
	# Get script.
	var source_script = session_scripts.get(source_name)
	if source_script is not Object: return null
	source_script = source_script as Object
	# Return value.
	var property_value = source_script.get(property_name)
	return property_value


func set_var(property_name:String, value:Variant, source_name:String='base') -> void:
	# Get script.
	var source_script = session_scripts.get(source_name)
	if source_script is not Object: return
	source_script = source_script as Object
	var old_value = get_var(property_name, source_name)
	# Set value.
	source_script.set(property_name, value)
	# Emit value changed signal.
	if session_ready && old_value != value:
		value_changed.emit(property_name, source_name)


func call_func(func_name:String, args:Array=[], source_name:String='base') -> Variant:
	# Get script.
	var source_script = session_scripts.get(source_name)
	if source_script is not Object: return
	source_script = source_script as Object
	# Call function & return value.
	return source_script.callv(func_name, args)


func reload_main_scene() -> void:
	var main_scene_ = SessionManager.get_scene('Main/main')
	var main_scene_instance:Node = main_scene_.instantiate()
	var tree:SceneTree = self.get_tree()
	tree.change_scene_to_node.call_deferred(main_scene_instance)
	SessionManager.main_scene = main_scene_instance


func get_accent_color() -> Color:
	var accent: Color

	match SessionManager.get_var('accent_mode'):
		0: # System.
			accent = DisplayServer.get_accent_color()
		1: # Dynamic.
			if not PlayerManager.queue.is_empty():
				accent = PlayerManager.get_current_track().album.get_album_dominant_color()
			else:
				accent = ThemeManager.accent_color
		2: # Custom.
			accent = SessionManager.get_var('custom_accent')

	return accent


## Get the scene at [param scene_name] for the current theme or [param theme_override].
func get_scene(scene_name:String, theme_override:String='', recurse:int=0) -> PackedScene:
	if recurse > 1: return null
	var theme_: String
	if theme_override.is_empty(): theme_ = get_var('theme')
	else: theme_ = theme_override

	var scene
	var scene_path:String = 'res://Layouts/%s/%s.tscn' % [theme_, scene_name]
	if ResourceLoader.exists(scene_path): scene = load(scene_path)
	if not scene: return SessionManager.get_scene(scene_name, 'Normal', recurse+1)
	return scene


## Returns the icon at [param icon_name] for the current theme or [param theme_override].
func get_icon(icon_name:String, theme_override:String='', recurse:int=0) -> Texture2D:
	if recurse > 1: return null
	var theme_: String
	if theme_override.is_empty(): theme_ = get_var('theme')
	else: theme_ = theme_override

	var icon
	var icon_path:String = 'res://Themes/%s/Assets/Icons/%s.svg' % [theme_, icon_name]
	if ResourceLoader.exists(icon_path): icon = load(icon_path)
	if icon is not Texture2D: return SessionManager.get_icon(icon_name, 'Normal', recurse+1)
	return icon


## Load session from disk.
## May override current playing track in PlayerManager.
func load_session() -> void:
	MiniLog.info('Loading session.', SessionManager)
	var data = import_config(session_file_path)
	if data is not Dictionary: return

	# Remove non-existent library IDs in visible libraries.
	var library_order:PackedStringArray = get_var('library_order')
	var visible_libraries:PackedStringArray = get_var('visible_libraries')
	for library_id:String in visible_libraries:
		if library_id not in library_order: visible_libraries.erase(library_id)

	# Load libraries.
	LibraryManager.load_libraries()

	# Load queue.
	var raw_queue = data.get('queue')
	var tracks:Array[DBTrack] = []
	if raw_queue is Array:
		for id in raw_queue:
			if id is not String: continue
			var track = DBTrack.from_id(id)
			if track: tracks.append(track)
	PlayerManager.set_queue(tracks)

	# Set queue position.
	var raw_queue_position = data.get('queue_position')
	if (raw_queue_position is int or raw_queue_position is float) && raw_queue_position != -1:
		PlayerManager.set_current_track(int(raw_queue_position), false)

	# Set track progress.
	var raw_track_progress = data.get('track_progress')
	if raw_track_progress is float:
		PlayerManager.set_track_progress(raw_track_progress)

	# Set volume.
	var raw_volume = data.get('volume')
	if raw_volume is float or raw_volume is int:
		PlayerManager.volume = raw_volume

	var raw_auto_queue_start_index = data.get('auto_queue_start_index')
	if (raw_auto_queue_start_index is int or raw_auto_queue_start_index is float) && raw_auto_queue_start_index != -1:
		PlayerManager.auto_queue_start_index = int(raw_auto_queue_start_index)

	# Emit session loaded signals.
	for script:Object in session_scripts.values():
		if script.has_method('session_loaded') && script.get_method_argument_count('session_loaded') == 0:
			script.call('session_loaded')
	session_loaded.emit()
	MiniLog.info('Session loaded.', SessionManager)


## Save the current session to disk.
func save_session() -> void:
	var data = {
		'library_order': PackedStringArray(),
		'queue': [],
		'queue_position': PlayerManager.queue_position,
		'auto_queue_start_index': PlayerManager.auto_queue_start_index,
		'track_progress': PlayerManager.track_progress,
		'volume': PlayerManager.volume,
	}

	# Sync library order & save changed libraries.
	var library_order:PackedStringArray = get_var('library_order')
	library_order.clear()
	for library:DBLibrary in LibraryManager.libraries:
		library_order.append(library.id)
		if library.changed: library.save()
	

	# Set data properties.
	for script in session_scripts.values():
		var property_data = script.get('property_data')
		if property_data is not Array: continue
		for i in property_data:
			if i is not Array: continue
			data.set(i[0], script.get(i[0]))

	# Set data queue.
	for track:DBTrack in PlayerManager.queue:
		data.queue.append(track.as_id())

	# Write file.
	var file := FileAccess.open(session_file_path, FileAccess.WRITE)
	var json = JSON.stringify(A2J.to_json(data), '\t', true, true)
	file.store_string(json)
	file.close()


func import_config(path:String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		file.close()
		return {}
	var data = A2J.from_json(JSON.parse_string(file.get_as_text()))
	file.close()
	if data == null: return {}

	# Apply properties.
	for script in session_scripts.values():
		var property_data = script.get('property_data')
		if property_data is not Array: continue
		for i in property_data:
			if i is not Array: continue
			var data_entry = data.get(i[0])
			if data_entry == null: continue
			if typeof(data_entry) == TYPE_FLOAT && TYPE_INT in i[1] && TYPE_FLOAT not in i[1]:
				data_entry = int(data_entry)
			if typeof(data_entry) in i[1]:
				script.set(i[0], data_entry)

	return data


## Exports preferences based on [param export_sections].
func export_config(path:String='user://session_export.json', export_sections:Array[String]=[]) -> void:
	var allowed_properties: PackedStringArray
	for section:Array in self.sections:
		if section[0] not in export_sections: continue
		for property:String in section[1]:
			allowed_properties.append(property)

	# Set data properties.
	var data = {}
	for script in session_scripts.values():
		var property_data = script.get('property_data')
		if property_data is not Array: continue
		for i in property_data:
			if i is not Array: continue
			if i[0] not in allowed_properties: continue
			data.set(i[0], script.get(i[0]))

	# Write file.
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json = JSON.stringify(A2J.to_json(data), '\t', true, true)
		file.store_string(json)
		file.close()


func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		current_window_size = get_window().size
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_session()
		get_tree().quit()
