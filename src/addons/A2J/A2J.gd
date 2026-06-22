@tool
## Main API for the Any-JSON plugin.
class_name A2J extends RefCounted

enum State {
	IDLE,
	SERIALIZING,
	DESERIALIZING,
}

## Primitive types that do not require handlers.
const primitive_types:Array[Variant.Type] = [
	TYPE_NIL,
	TYPE_BOOL,
	TYPE_INT,
	TYPE_FLOAT,
	TYPE_STRING,
]

## The default ruleset used when serializing or deserializing.
const default_ruleset:Dictionary[String,Dictionary] = {
	# Rules applied everywhere.
	'@global': {
		'type_exclusions': [
			'RID',
			'Signal',
			'Callable',
		],
		'type_inclusions': [],
		'class_exclusions': [],
		'class_inclusions': [],
		'exclude_private_properties': true,
		'exclude_default_values': true,
		'automatic_resource_references': true,
	},
	# Rules applied only to the [class Resource] class.
	'Resource': {
		'property_exclusions': [
			'resource_local_to_scene',
			'resource_path',
			'resource_name',
			'resource_scene_unique_id',
			'resource_priority',
		],
	}
}

const error_strings:PackedStringArray = [
	'No handler implemented for type "%s". Make a handler with the abstract A2JTypeHandler class.',
	'"type_exclusions" & "type_inclusions" in ruleset should be structured as follows: Array[String].',
	'"class_exclusions" & "class_inclusions" in ruleset should be structured as follows: Array[String].',
]


# Template for instantiator function.
static func _default_instantiator_function(registered_object:Object, _object_class:StringName, args:Array=[]) -> Object:
	return registered_object.callv('new', args)


static var _vector_type_handler := A2JVectorTypeHandler.new()
static var _packed_array_type_handler := A2JPackedArrayTypeHandler.new()
static var _misc_type_handler := A2JMiscTypeHandler.new()
static var _object_type_handler := A2JObjectTypeHandler.new()
static var _array_type_handler := A2JArrayTypeHandler.new()
static var _dictionary_type_handler := A2JDictionaryTypeHandler.new()
## A2JTypeHandlers that can be used.
## You can add custom type handlers here.
static var type_handlers:Dictionary[String,A2JTypeHandler] = {
	'Ref':A2JReferenceTypeHandler.new(),
	'Obj':_object_type_handler, 'Object':_object_type_handler,
	'Array':_array_type_handler,
	'Dictionary':_dictionary_type_handler,
	'Vector':_vector_type_handler, 'VectorI':_vector_type_handler, 'Vector2':_vector_type_handler, 'Vector2i':_vector_type_handler,
	'Vector3':_vector_type_handler, 'Vector3i':_vector_type_handler,
	'Vector4':_vector_type_handler, 'Vector4i':_vector_type_handler,
	'PackedByteArray':_packed_array_type_handler,
	'PackedInt32Array':_packed_array_type_handler, 'PackedInt64Array':_packed_array_type_handler,
	'PackedFloat32Array':_packed_array_type_handler, 'PackedFloat64Array':_packed_array_type_handler,
	'PackedVector2Array':_packed_array_type_handler, 'PackedVector3Array':_packed_array_type_handler, 'PackedVector4Array':_packed_array_type_handler,
	'PackedColorArray':_packed_array_type_handler,
	'PackedStringArray':_packed_array_type_handler,
	'StringName':_misc_type_handler,
	'NodePath':_misc_type_handler,
	'Color':_misc_type_handler,
	'Plane':_misc_type_handler,
	'Quaternion':_misc_type_handler,
	'Rect2':_misc_type_handler, 'Rect2i':_misc_type_handler,
	'AABB':_misc_type_handler,
	'Basis':_misc_type_handler,
	'Transform2D':_misc_type_handler, 'Transform3D':_misc_type_handler,
	'Projection':_misc_type_handler,
}

## Set of recognized classes used for conversion to & from AJSON.
## You can safely add or remove classes from this registry as you see fit.
## [br][br]
## Is, by default; equipped with many but not all built-in Godot classes.
## [br]
## This also means if your game export excludes certain classes you may need to remove them from here.
static var object_registry:Dictionary[StringName,Object] = {
	'Object':Object, 'Resource':Resource, 'GDScript':GDScript,
	'DBLibrary':DBLibrary, 'DBPlaylist':DBPlaylist, 'DBArtist':DBArtist, 'DBAlbum':DBAlbum, 'DBTrack':DBTrack,
}


## Listens for errors.
static var error_server := A2JErrorServer.new()
## Current state of A2J.
static var current_state:State = State.IDLE
## The time in milliseconds spent during the last [code]to_json[/code] or [code]from_json[/code] call.
static var time_to_finish:float = 0

## Data that [A2JTypeHandler] objects can share & use during serialization.
## Cleared before & after [code]to_json[/code] or [code]from_json[/code] is called.
## [br][br]
## Default fields:
## [br]- [param variant_map: Dictionary[int,Variant]]
static var _process_data: Dictionary

## The raw ruleset currently being used in serialization. Gets reset to the default ruleset after serialization.
static var _current_ruleset := default_ruleset

## Array of functions for [A2JTypeHandler] objects to add to. Will be called in order after the main serialization has completed.
static var _process_next_pass_functions:Array[Callable] = []

## Array of property names, pointing to where the data structure being serialized is currently at.
## Used to find exactly where in the data structure an error was found.
static var _tree_position: Array[String]
const _default_tree_position:Array[String] = ['ROOT']


## Do not instantiate this class. All functions & variables are static.
func _init() -> void:
	assert(false, 'A2J class should not be instantiated.')


## Returns the version of the plugin. If version could not be found, returns an empty string.
static func get_version() -> String:
	var config_file := ConfigFile.new()
	config_file.load('res://addons/A2J/plugin.cfg')
	return config_file.get_value('plugin', 'version', '')


## Report an error to Any-JSON.
## [param translations] should be strings.
static func report_error(error:int, ...translations) -> void:
	var a2jError_ = A2JTypeHandler.a2jError % ['A2J', ' > '.join(A2J._tree_position)]
	var message = error_strings.get(error)
	if message is not String: printerr(a2jError_+str(error))
	else:
		message = message % translations
		printerr(a2jError_+message)
	# Emit error.
	error_server.core_error.emit(error, message)


## Convert [param value] to an AJSON object or a JSON friendly value.
## If [param value] is an [Object], only objects in the [code]object_registry[/code] can be converted.
## [br][br]
## Returns [code]null[/code] if failed.
static func to_json(value:Variant, ruleset:Dictionary[String,Dictionary]=_current_ruleset) -> Variant:
	var start_tick := Time.get_ticks_usec()
	current_state = State.SERIALIZING
	_current_ruleset = ruleset
	_tree_position = _default_tree_position.duplicate()
	_process_next_pass_functions.clear()
	_process_data.clear()
	_init_handler_data()
	var result = _to_json(value, ruleset)
	result = _call_next_pass_functions(value, result, ruleset)
	_process_data.clear()
	_current_ruleset = default_ruleset
	current_state = State.IDLE
	time_to_finish = (Time.get_ticks_usec()-start_tick)/1000.0
	return result


static func _to_json(value:Variant, raw_ruleset:Dictionary[String,Dictionary]=_current_ruleset) -> Variant:
	var ruleset := _get_runtime_ruleset(value, raw_ruleset)

	# Get type of value.
	var type := type_string(typeof(value))
	var object_class: String
	if type == 'Object': object_class = A2JUtil.get_class_name(value)

	# If type excluded, return null.
	if _type_excluded(type, ruleset): return null
	# If class excluded, return null.
	elif object_class && _class_excluded(object_class, ruleset): return null
	# If type is primitive, return value unchanged (except when rules apply).
	if typeof(value) in primitive_types:
		# Apply float snapping.
		if value is float:
			var snap_value = ruleset.get('snap_floats_to', null)
			if snap_value is float: value = snappedf(value, snap_value)
		return value

	# Get type handler.
	var handler = type_handlers.get(type, null)
	if handler == null:
		report_error(0, type)
		return null
	handler = handler as A2JTypeHandler

	# Call midpoint function.
	var midpoint = ruleset.get('midpoint')
	if midpoint is Callable:
		# If returns true, discard conversion.
		if midpoint.call(value, ruleset) == true: return null

	# Return converted value.
	return handler.to_json(value, ruleset)


## Convert [param value] to it's original value. Returns [code]null[/code] if failed.
static func from_json(value, ruleset:Dictionary[String,Dictionary]=_current_ruleset) -> Variant:
	var start_tick := Time.get_ticks_usec()
	current_state = State.DESERIALIZING
	_current_ruleset = ruleset
	_tree_position = _default_tree_position.duplicate()
	_process_next_pass_functions.clear()
	_process_data.clear()
	_init_handler_data()
	var result = _from_json(value, ruleset)
	result = _call_next_pass_functions(value, result, ruleset)
	_process_data.clear()
	_current_ruleset = default_ruleset
	current_state = State.IDLE
	time_to_finish = (Time.get_ticks_usec()-start_tick)/1000.0
	return result


## [param type_details] tells the function how to type the result.
static func _from_json(value, type_details:Dictionary={}, raw_ruleset:Dictionary[String,Dictionary]=_current_ruleset) -> Variant:
	var ruleset = _get_runtime_ruleset(value, raw_ruleset)

	# Get type of value.
	var type: String
	var object_class: String
	var headers: PackedStringArray
	if value is Dictionary:
		headers = value.get('.t', '').split(':')
		type = headers[0]
		if headers.size() == 2: object_class = headers[1]
		if type == '': type = 'Dictionary'
	elif value is Array: type = 'Array'
	else: type = type_string(typeof(value))
	if headers.is_empty(): headers.append(type)
	else: headers[0] = type

	# If type excluded, return null.
	if _type_excluded(type, ruleset): return null
	# If class excluded, return null.
	elif object_class && _class_excluded(object_class, ruleset): return null
	# If type is primitive.
	elif typeof(value) in primitive_types:
		# If float is a whole number, convert to an int (JSON in Godot converts ints to floats, we need to convert them back).
		if value is float && fmod(value, 1) == 0: return int(value)
		# Apply float snapping.
		if value is float:
			var snap_value = ruleset.get('snap_floats_to', null)
			if snap_value is float: value = snappedf(value, snap_value)
		return value

	# Get type handler.
	var handler = type_handlers.get(type, null)
	if handler == null:
		report_error(0, type)
		return null
	handler = handler as A2JTypeHandler

	# Call midpoint function.
	var midpoint = ruleset.get('midpoint')
	if midpoint is Callable:
		# If returns true, discard conversion.
		if midpoint.call(value, ruleset) == true: return null

	# Convert value.
	var result
	# Type dictionary.
	if type == 'Dictionary':
		result = handler.from_json(headers, value, ruleset, A2JUtil.type_dictionary({}, type_details))
	# Type array.
	elif type == 'Array':
		result = handler.from_json(headers, value, ruleset, A2JUtil.type_array([], type_details))
	# Type other.
	elif type_details.get('type') is int:
		result = handler.from_json(headers, value, ruleset)
		result = type_convert(result, type_details.get('type'))
	else:
		result = handler.from_json(headers, value, ruleset)
	# Return result.
	return result


## Get the runtime ruleset.
static func _get_runtime_ruleset(variant:Variant, ruleset:Dictionary[String,Dictionary]) -> Dictionary:
	var result:Dictionary = {}
	for key:String in ruleset:
		var rule_group:Dictionary = ruleset[key]

		# Determine if the group is valid in this instance.
		var valid:bool = false
		if key == '@global': valid = true
		elif key.begins_with('@depth'):
			var expression:String = key.split(':')[-1]
			var expected_depth:int = expression.to_int()
			var current_depth:int = _tree_position.size()-1
			if expression.ends_with('+'):
				if current_depth >= expected_depth: valid = true
			elif expression.ends_with('-'):
				if current_depth <= expected_depth: valid = true
			else:
				if current_depth == expected_depth: valid = true
		elif variant is Object:
			valid = A2JUtil.get_class_name(variant) == key or variant.is_class(key)
		# Skip group if invalid.
		if not valid: continue

		# Merge rule group with result.
		for key_2:String in rule_group:
			var valid_2:bool = true
			var split_key := key_2.split('@')
			if split_key[-1] == 'ser' && current_state != State.SERIALIZING: valid_2 = false
			elif split_key[-1] == 'des' && current_state != State.DESERIALIZING: valid_2 = false
			if not valid_2: continue
			var new_key:String = split_key[0]
			var value = rule_group[new_key]
			if not result.has(new_key):
				result.set(new_key, value)
				continue
			elif value is Array:
				result[new_key].append_array(value)
			elif value is Dictionary:
				result[new_key].merge(value, true)

	return result


## Returns whether or not the [param type] is excluded in the [param ruleset].
static func _type_excluded(type:String, ruleset:Dictionary) -> bool:
	# Get type exclusions & inclusions.
	var type_exclusions = ruleset.get('type_exclusions', [])
	var type_inclusions = ruleset.get('type_inclusions', [])
	# Return whether or not the type is excluded.
	if type_exclusions is Array && type_inclusions is Array:
		return type in type_exclusions or (type_inclusions.size() > 0 && type not in type_inclusions)

	# Throw error if is not an array.
	report_error(1)
	return true


## Returns whether or not the [param object_class] is excluded in the [param ruleset].
static func _class_excluded(object_class:String, ruleset:Dictionary) -> bool:
	# Get class exclusions & inclusions.
	var class_exclusions = ruleset.get('class_exclusions', [])
	var class_inclusions = ruleset.get('class_inclusions', [])
	# Return whether or not class is excluded.
	if class_exclusions is Array && class_inclusions is Array:
		return object_class in class_exclusions or (class_inclusions.size() > 0 && object_class not in class_inclusions)

	# Throw error if is not an array.
	report_error(2)
	return true


## Initialize data for all registered [code]type_handlers[/code], into the [code]_process_data[/code] variable.
static func _init_handler_data() -> void:
	_process_data.set('variant_map', {})
	for key:String in type_handlers:
		var handler:A2JTypeHandler = type_handlers[key]
		_process_data.merge(handler.init_data.duplicate(true), true)


## Calls all functions in [code]_process_next_pass_functions[/code] with the given [param value], [param result], & [param ruleset] (in that order).
## [param result] is changed to the return value of the last next pass function & [param result] is returned after all functions have been called.
static func _call_next_pass_functions(value, result, ruleset:Dictionary) -> Variant:
	for callable:Callable in _process_next_pass_functions:
		result = callable.call(value, result, ruleset)
	return result
