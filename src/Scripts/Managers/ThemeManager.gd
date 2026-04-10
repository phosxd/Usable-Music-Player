extends Node


## All registered themes.
var registered_themes:Array[Dictionary] = [
	{
		'id': 'UMP_DEFAULT', # Internal ID, must be unique.
		'name': 'Normal', # Display name.
		'item': preload('res://Themes/Normal/theme.tres'), # Can be [Theme] or a [TesseractMod] theme.
	},
]

## The global theme applied to every part of the app.
## Setting this will immediately update the GUI.
var theme: Theme:
	set(value):
		theme = value
		get_window().theme = value

		# Set main scene.
		var main_scene = SessionManager.get_layout_theme_scene('Main/main')
		var main_scene_instance:Node = main_scene.instantiate()
		var tree:SceneTree = get_tree()
		tree.change_scene_to_node.call_deferred(main_scene_instance)
		SessionManager.main_scene = main_scene_instance

		MiniLog.info('Set theme to "$~%s~$".' % theme.resource_path, ThemeManager)


#region variables

## Tint color applied to all panel elements.
var panel_tint := Color.WHITE:
	set(value):
		panel_tint = value

## Corner radius applied to all [TextureRectRounded] nodes.
var image_corner_radius:int = 8:
	set(value):
		image_corner_radius = value

#endregion


func _ready() -> void:
	# Load themes from mods.
	for mod:TesseractMod in TesseractAPI.mod_instances.values():
		if mod.config.get_value('TesseractMod', 'type', '') != 'theme': continue
		registered_themes.append({
			'id': mod.id,
			'name': mod.name,
			'item': mod,
		})


func set_theme(id:String) -> void:
	var theme_index:int = registered_themes.find_custom(func(item:Dictionary) -> bool:
		return item.get('id') as String == id
	)
	if theme_index == -1:
		MiniLog.err('Could not find theme with ID "%s".' % id, ThemeManager)
		return

	var registered_theme:Dictionary = registered_themes[theme_index]
	var theme_name = registered_theme.get('name')
	if theme_name is not String or theme_name.is_empty(): theme_name = id

	var theme_item = registered_theme.get('item')
	if theme_item is Theme:
		theme = theme_item
	elif theme_item is TesseractMod:
		var theme_path:String = 'res://Themes/%s/theme.tres' % theme_item.id
		if ResourceLoader.exists(theme_path):
			var theme_resource = load(theme_path)
			if theme_resource is Theme: theme = theme_resource


## Returns the index of the registered theme in [param registered_themes] with the specified [param id], or [code]-1[/code] if not found.
func get_theme_index(id:String) -> int:
	return registered_themes.find_custom(func(item:Dictionary) -> bool:
		return item.id == id
	)

## Loads a [Theme] from the given [param mod].
#func set_theme_from_mod(mod:TesseractMod) -> void:
	## Set main scene.
	#var tree:SceneTree = get_tree()
	#tree.change_scene_to_packed.call_deferred(SessionManager.get_layout_theme_scene('Main/main'))
	#SessionManager.main_scene = tree.current_scene
#
	## Set theme.
	#var theme_path:String = 'res://Themes/%s/theme.tres' % mod.id
	#if ResourceLoader.exists(theme_path):
		#var theme_resource = load(theme_path)
		#if theme_resource is Theme: theme = theme_resource
#
	#if mod is TesseractMod:
		#var cfg_image_corner_radius = mod.config.get_value('Theme', 'image_corner_radius', 8)
		#if cfg_image_corner_radius is int: image_corner_radius = cfg_image_corner_radius
	#else:
		#image_corner_radius = 8
