extends Node

signal theme_applied

const variable_names:Array[String] = [
	'image_corner_radius',
	'accent_color',
	'bg_color',
	'global_margin',
	'tools_margin',
	'sidebar_margin',
	'right_sidebar_margin',
	'search_margin',
	'panel_color',
	'section_panel_color',
	'text_color',
	'text_disabled_color',
	'text_hover_color',
	'text_primary_color',
	'text_primary_hover_color',
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
## Call [member apply_changes] to apply the theme.
var theme:Theme = registered_themes[0].item:
	set(value):
		theme = value.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		original_theme = value
		MiniLog.info('Set theme to "$~%s~$".' % original_theme.resource_path, ThemeManager)

var original_theme: Theme


## Current theme mode. [code]0[/code] is default.
var mode:int = 0


#region theme tweaks

## Theme accent override.
var accent_override_color := Color.WHITE:
	set(value):
		accent_override_color = value
		theme.set_color('accent_color', 'Control', value)
		# AccentButton.
		for item in ['icon_normal_color', 'icon_disabled_color', 'icon_hover_color', 'icon_pressed_color', 'icon_hover_pressed_color']:
			theme.set_color(item, 'AccentButton', value)
			theme.set_color(item, 'SoftButton', value)
		# HSlider.
		set_stylebox_color('HSlider', 'grabber_area', 'bg_color', value)
		set_stylebox_color('HSlider', 'grabber_area_highlight', 'bg_color', value)
		# CheckButton.
		var icon:Texture2D = theme.get_icon('checked', 'CheckButton')
		if icon is DPITexture:
			var keys = icon.color_map.keys()
			if keys.size() > 0:
				icon.color_map[keys[0]] = value
				icon = DPITexture.create_from_string(icon._source, icon.base_scale, icon.saturation, icon.color_map)
				theme.set_icon('checked', 'CheckButton', icon)

var panel_tint := Color.TRANSPARENT:
	set(value):
		panel_tint = value
		self.set('bg_color', bg_color)
		self.set('panel_color', panel_color)
		self.set('tooltip_panel_color', tooltip_panel_color)
		self.set('section_panel_color', section_panel_color)

var button_tint := Color.TRANSPARENT:
	set(value):
		button_tint = value
		self.set('button_color', button_color)
		self.set('button_disabled_color', button_disabled_color)
		self.set('button_hover_color', button_hover_color)
		self.set('button_pressed_color', button_pressed_color)

#endregion

#region theme variables

## All theme modes & their config values.
var modes:Array[Dictionary] = []

## Corner radius applied to all [TextureRectRounded] nodes.
var image_corner_radius:int = 8

var accent_color: Color

## Default background color. Setting this will not change it's value.
var default_bg_color: Color:
	get():
		return registered_themes[0].config.get_value('Theme','bg_color')

## App background color. If transparent, uses default theme color.
var bg_color := Color.TRANSPARENT:
	set(value):
		bg_color = value
		if value.a == 0: value = default_bg_color
		value = value.blend(panel_tint)
		_bg_color = value

var _bg_color: Color

var global_margin:Array = [0,0,0,0]:
	set(value):
		global_margin = value
		if SessionManager.main_scene != null: SessionManager.main_scene.set('global_margin', value)

var tools_margin:Array = [0,0,0,0]:
	set(value):
		tools_margin = value
		if SessionManager.main_scene != null: SessionManager.main_scene.set('tools_margin', value)

var sidebar_margin:Array = [0,0,0,0]:
	set(value):
		sidebar_margin = value
		if SessionManager.main_scene != null: SessionManager.main_scene.set('sidebar_margin', value)

var right_sidebar_margin:Array = [0,0,0,0]:
	set(value):
		right_sidebar_margin = value
		if SessionManager.main_scene != null: SessionManager.main_scene.set('right_sidebar_margin', value)

var search_margin:Array = [0,0,0,0]:
	set(value):
		search_margin = value
		if SessionManager.main_scene != null: SessionManager.main_scene.set('search_margin', value)

var panel_color := Color.TRANSPARENT:
	set(value):
		panel_color = value
		value = value.blend(panel_tint)
		set_stylebox_color('PanelContainer', 'panel', 'bg_color', value)
		set_stylebox_color('GridItemPanel', 'panel', 'bg_color', value)
		set_stylebox_color('IslandPanelContainer', 'panel', 'bg_color', value)
		set_stylebox_color('ToolsIslandPanelContainer', 'panel', 'bg_color', value)
		set_stylebox_color('LineEdit', 'normal', 'bg_color', value)
		set_stylebox_color('LineEdit', 'read_only', 'bg_color', value)

var section_panel_color := Color.TRANSPARENT:
	set(value):
		section_panel_color = value
		value = value.blend(panel_tint)
		set_stylebox_color('SectionPanelContainer', 'panel', 'bg_color', value)

var tooltip_panel_color := Color.TRANSPARENT:
	set(value):
		tooltip_panel_color = value
		value = value.blend(panel_tint)
		set_stylebox_color('TooltipPanel', 'panel', 'bg_color', value)
		set_stylebox_color('PopupMenu', 'panel', 'bg_color', value)

var text_color := Color.TRANSPARENT:
	set(value):
		text_color = value
		set_color('Label', 'font_color', value)
		set_color('RichTextLabel', 'default_color', value)
		set_color('LineEdit', 'font_color', value)
		set_color('Button', 'font_color', value)
		set_color('AccentButton', 'font_color', value)

var text_disabled_color := Color.TRANSPARENT:
	set(value):
		text_disabled_color = value
		theme.set_color('font_uneditable_color', 'LineEdit', value)
		theme.set_color('font_placeholder_color', 'LineEdit', value)
		theme.set_color('font_disabled_color', 'Button', value)
		theme.set_color('font_disabled_color', 'AccentButton', value)

var text_hover_color := Color.TRANSPARENT:
	set(value):
		text_hover_color = value
		for item in ['Button','AccentButton']:
			for item_2 in ['font_hover_color','font_focused_color','font_pressed_color','font_hover_pressed_color']:
				theme.set_color(item_2, item, value)
		theme.set_color('font_color', 'LabelHover', value)
		theme.set_color('font_outline_color', 'LabelHover', value)

var text_primary_color := Color.TRANSPARENT:
	set(value):
		text_primary_color = value
		theme.set_color('font_color', 'LabelPrimary', value)
		theme.set_color('font_outline_color', 'LabelPrimary', value)
		theme.set_color('font_color', 'LabelPrimarySmall', value)
		theme.set_color('font_outline_color', 'LabelPrimarySmall', value)
		theme.set_color('font_color', 'LabelHeader', value)
		theme.set_color('font_outline_color', 'LabelHeader', value)

var text_primary_hover_color := Color.TRANSPARENT:
	set(value):
		text_primary_hover_color = value
		theme.set_color('font_color', 'LabelPrimaryHover', value)
		theme.set_color('font_outline_color', 'LabelPrimaryHover', value)
		theme.set_color('font_color', 'LabelHeaderHover', value)
		theme.set_color('font_outline_color', 'LabelHeaderHover', value)

var button_color := Color.TRANSPARENT:
	set(value):
		button_color = value
		value = value.blend(button_tint)
		set_stylebox_color('Button', 'normal', 'bg_color', value, true)

var button_disabled_color := Color.TRANSPARENT:
	set(value):
		button_disabled_color = value
		set_stylebox_color('Button', 'disabled', 'bg_color', value.blend(button_tint), true)

var button_hover_color := Color.TRANSPARENT:
	set(value):
		button_hover_color = value
		set_stylebox_color('Button', 'hover', 'bg_color', value.blend(button_tint), true)

var button_pressed_color := Color.TRANSPARENT:
	set(value):
		button_pressed_color = value
		set_stylebox_color('Button', 'pressed', 'bg_color', value.blend(button_tint), true)

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
	if theme_item is Theme:
		theme = theme_item
		SessionManager.reload_main_scene()
	elif theme_item is TesseractMod:
		var theme_path:String = 'res://Themes/%s/theme.tres' % theme_item.id
		if not ResourceLoader.exists(theme_path):
			MiniLog.err('Could not find theme resource in mod "%s".' % theme_item.id, ThemeManager)
			return
		# Set theme.
		var theme_resource = load(theme_path)
		if theme_resource is Theme:
			theme = theme_resource
			SessionManager.reload_main_scene()

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

	if modes.size() == 0:
		var mode_config = {
			'@mode_name': 'Default',
		}
		modes.append(mode_config)

	set_theme_mode(0)


func set_theme_mode(index:int) -> void:
	if modes.size() <= index: return
	var mode_config = modes.get(index)
	mode = index

	# Reset variables.
	var i:int = -1
	for variable:String in variable_names:
		i += 1
		if variable in mode_config: continue
		self.set(variable, variable_defaults[i])

	mode_config = mode_config as Dictionary
	for key in mode_config:
		if key is not String or key.begins_with('@'): continue
		self.set(key, mode_config[key]) # Set property to value. If mismatched type, nothing happens.

	apply_changes()


## Returns the currently used registered theme.
func get_current_theme() -> Dictionary:
	return registered_themes[get_theme_index(SessionManager.theme)]


## Returns the index of the registered theme in [param registered_themes] with the specified [param id], or [code]-1[/code] if not found.
func get_theme_index(id:String) -> int:
	return registered_themes.find_custom(func(item:Dictionary) -> bool:
		return item.id == id
	)


#region theme manipulation

## Apply changes made to [member theme].
func apply_changes() -> void:
	get_window().theme = self.theme.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if SessionManager.main_scene != null: SessionManager.main_scene.set('bg_color', self._bg_color)
	self.theme_applied.emit()


## Gets the [member theme] or [param theme_resource] stylebox property.
func get_stylebox_property(theme_type:String, style_name:String, property_name:String, theme_resource=null) -> Variant:
	if theme_resource is not Theme: theme_resource = theme
	if not theme.has_stylebox(style_name, theme_type): return
	var style:StyleBox = theme_resource.get_stylebox(style_name, theme_type)
	return style.get(property_name)


## Sets the [member original_theme] stylebox property.
## If [param use_default_theme] is [code]true[/code] will grab from the app default theme instead of the current theme.
func get_stylebox_default_property(theme_type:String, style_name:String, property_name:String, use_default_theme:bool=false) -> Variant:
	var theme_resource = original_theme
	if use_default_theme: theme_resource = registered_themes[0].item
	return get_stylebox_property(theme_type, style_name, property_name, theme_resource)


## Sets the [member theme] stylebox property.
func set_stylebox_property(theme_type:String, style_name:String, property_name:String, property_value:Variant) -> void:
	if not theme.has_stylebox(style_name, theme_type): return
	var style:StyleBox = theme.get_stylebox(style_name, theme_type)
	style.set(property_name, property_value)
	theme.set_stylebox(style_name, theme_type, style)


## Sets the [member theme] stylebox color, with modifiers.
func set_stylebox_color(theme_type:String, style_name:String, property_name:String, property_value:Color, use_default_if_transparent:bool=true, preserve_alpha:bool=true) -> void:
	if use_default_if_transparent && property_value.a == 0:
		var default = get_stylebox_default_property(theme_type, style_name, property_name)
		if default == null: default = get_stylebox_default_property(theme_type, style_name, property_name, true)
	if preserve_alpha:
		var alpha:float = get_stylebox_default_property(theme_type, style_name, property_name).a
		property_value = Color(property_value.r, property_value.g, property_value.b, alpha)
	set_stylebox_property(theme_type, style_name, property_name, property_value)


## Sets the [member theme] color, with modifiers.
func set_color(theme_type:String, property_name:String, property_value:Color, use_default_if_transparent:bool=true, preserve_alpha:bool=true) -> void:
	if use_default_if_transparent && property_value.a == 0:
		property_value = original_theme.get_color(property_name, theme_type)
	if preserve_alpha:
		var alpha:float = original_theme.get_color(property_name, theme_type).a
		property_value = Color(property_value.r, property_value.g, property_value.b, alpha)
	theme.set_color(property_name, theme_type, property_value)

#endregion
