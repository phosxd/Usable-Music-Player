extends Node

const variable_names:Array[String] = [
	'image_corner_radius',
	'bg_color',
	'panel_color',
	'section_panel_color',
	'text_color',
	'text_disabled_color',
	'text_hover_color',
	'text_primary_color',
	'button_color',
	'button_disabled_color',
	'button_hover_color',
	'button_pressed_color',
]
var variable_defaults:Array[Variant] = []


## All registered themes.
var registered_themes:Array[Dictionary] = [
	{
		'id': 'UMP_DEFAULT', # Internal ID, must be unique.
		'name': 'Normal', # Display name.
		'item': preload('res://Themes/Normal/theme.tres'), # Can be [Theme] or a [TesseractMod] theme.
		'config': ConfigFile.new(),
	},
]

## The global theme applied to every part of the app.
## Setting this will immediately update the GUI.
var theme:Theme = registered_themes[0].item:
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


## Current theme mode. [code]0[/code] is default.
var mode:int = 0


#region variables

## All theme modes & their config values.
var modes:Array[Dictionary] = []

## Corner radius applied to all [TextureRectRounded] nodes.
var image_corner_radius:int = 8:
	set(value):
		image_corner_radius = value

## App background color. If transparent, uses default theme color.
var bg_color := Color.TRANSPARENT:
	set(value):
		bg_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','bg_color')
		value = value.blend(panel_tint)
		if SessionManager.main_scene != null: SessionManager.main_scene.set('bg_color', value)

var panel_tint := Color.TRANSPARENT:
	set(value):
		panel_tint = value
		self.set('bg_color', bg_color)
		self.set('panel_color', panel_color)
		self.set('section_panel_color', section_panel_color)

var button_tint := Color.TRANSPARENT:
	set(value):
		button_tint = value
		self.set('button_color', button_color)
		self.set('button_disabled_color', button_disabled_color)
		self.set('button_hover_color', button_hover_color)
		self.set('button_pressed_color', button_pressed_color)


func _ensure_stylebox(theme_style:String, property:String) -> StyleBox:
	if not theme.has_stylebox(property, theme_style):
		theme.set_stylebox(property, theme_style, registered_themes[0].item.get_stylebox(property, theme_style))
	return theme.get_stylebox(property, theme_style)


var panel_color := Color.TRANSPARENT:
	set(value):
		panel_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','panel_color')
		value = value.blend(panel_tint)
		var style:StyleBox = _ensure_stylebox('PanelContainer', 'panel')
		if style is StyleBoxFlat: style.bg_color = value

var section_panel_color := Color.TRANSPARENT:
	set(value):
		section_panel_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','section_panel_color')
		value = value.blend(panel_tint)
		var style:StyleBox = _ensure_stylebox('SectionPanelContainer', 'panel')
		if style is StyleBoxFlat: style.bg_color = value

var text_color := Color.TRANSPARENT:
	set(value):
		text_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','text_color')
		theme.set_color('font_color', 'Label', value)
		theme.set_color('font_color', 'Button', value)
		theme.set_color('font_color', 'AccentButton', value)

var text_disabled_color := Color.TRANSPARENT:
	set(value):
		text_disabled_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','text_disabled_color')
		theme.set_color('font_disabled_color', 'Button', value)
		theme.set_color('font_disabled_color', 'AccentButton', value)

var text_hover_color := Color.TRANSPARENT:
	set(value):
		text_hover_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','text_hover_color')
		for item in ['Button','AccentButton']:
			for item_2 in ['font_hover_color','font_focused_color','font_pressed_color','font_hover_pressed_color']:
				theme.set_color(item_2, item, value)

var text_primary_color := Color.TRANSPARENT:
	set(value):
		text_primary_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','text_primary_color')
		theme.set_color('font_color', 'PrimaryLabel', value)
		theme.set_color('font_outline_color', 'PrimaryLabel', value)

var button_color := Color.TRANSPARENT:
	set(value):
		button_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','button_color')
		value = value.blend(button_tint)
		var style:StyleBox = _ensure_stylebox('Button', 'normal')
		if style is StyleBoxFlat: style.bg_color = value

var button_disabled_color := Color.TRANSPARENT:
	set(value):
		button_disabled_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','button_disabled_color')
		value = value.blend(button_tint)
		var style:StyleBox = _ensure_stylebox('Button', 'disabled')
		if style is StyleBoxFlat: style.bg_color = value

var button_hover_color := Color.TRANSPARENT:
	set(value):
		button_hover_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','button_hover_color')
		value = value.blend(button_tint)
		var style:StyleBox = _ensure_stylebox('Button', 'hover')
		if style is StyleBoxFlat: style.bg_color = value

var button_pressed_color := Color.TRANSPARENT:
	set(value):
		button_pressed_color = value
		if value == Color.TRANSPARENT: value = registered_themes[0].config.get_value('Theme','button_pressed_color')
		value = value.blend(button_tint)
		var style:StyleBox = _ensure_stylebox('Button', 'pressed')
		if style is StyleBoxFlat: style.bg_color = value

#endregion


func _ready() -> void:
	registered_themes[0].config.load('res://Themes/Normal/CONFIG.cfg')

	for variable in variable_names:
		variable_defaults.append(self.get(variable))

	# Load themes from mods.
	for mod:TesseractMod in TesseractAPI.mod_instances.values():
		if mod.config.get_value('TesseractMod', 'type', '') != 'theme': continue
		registered_themes.append({
			'id': mod.id,
			'name': mod.name,
			'item': mod,
			'config': mod.config,
		})


func set_theme(id:String) -> void:
	var theme_index:int = registered_themes.find_custom(func(item:Dictionary) -> bool:
		return item.get('id') as String == id
	)
	if theme_index == -1:
		MiniLog.err('Could not find theme with ID "%s".' % id, ThemeManager)
		set_theme('UMP_DEFAULT')
		return
	modes.clear()

	var registered_theme:Dictionary = registered_themes[theme_index]
	var theme_name = registered_theme.get('name')
	if theme_name is not String or theme_name.is_empty(): theme_name = id

	var theme_item = registered_theme.get('item')
	if theme_item is Theme: theme = theme_item
	elif theme_item is TesseractMod:
		var theme_path:String = 'res://Themes/%s/theme.tres' % theme_item.id
		if not ResourceLoader.exists(theme_path):
			MiniLog.err('Could not find theme resource in mod "%s".' % theme_item.id, ThemeManager)
			return
		# Set theme.
		var theme_resource = load(theme_path)
		if theme_resource is Theme: theme = theme_resource

	# Set config values.
	var config:ConfigFile = registered_theme.config
	for section in config.get_sections():
		if not section.begins_with('Theme'): continue
		var mode_name:String = 'Default'
		if section.begins_with('Theme:'): mode_name = section.replace('Theme:','')
		var mode_config = {
			'@mode_name': mode_name,
		}
		for key:String in config.get_section_keys(section):
			if key in ['modes']: continue
			if self.get(key) == null: continue
			var value = config.get_value(section, key)
			if value != null: mode_config.set(key, value)
		modes.append(mode_config)

	set_theme_mode(0)


func set_theme_mode(index:int) -> void:
	if index == mode: return
	var mode_config = modes.get(index)
	if mode_config == null: return
	mode = index

	# Reset variables.
	var i:int = 0
	for variable in variable_names:
		self.set(variable, variable_defaults[i])
		i += 1

	mode_config = mode_config as Dictionary
	for key in mode_config:
		if key is not String or key.begins_with('@'): continue
		self.set(key, mode_config[key]) # Set property to value. If mismatched type, nothing happens.


## Returns the currently used registered theme.
func get_current_theme() -> Dictionary:
	return registered_themes[get_theme_index(SessionManager.theme)]


## Returns the index of the registered theme in [param registered_themes] with the specified [param id], or [code]-1[/code] if not found.
func get_theme_index(id:String) -> int:
	return registered_themes.find_custom(func(item:Dictionary) -> bool:
		return item.id == id
	)
