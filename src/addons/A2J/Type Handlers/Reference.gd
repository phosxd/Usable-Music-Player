class_name A2JReferenceTypeHandler extends A2JTypeHandler


func _init() -> void:
	error_strings = [
		'"references" in ruleset should be structured as follows: Dictionary[String,Variant].',
		'Could not load referenced resource at "~~".',
		'Cannot convert from an invalid JSON representation.',
	]


static func make_reference(name:String) -> Dictionary[String,Variant]:
	if name.is_valid_int():
		return {
			'.t': 'Ref:'+name,
		}
	else:
		return {
			'.t': 'Ref',
			'v': name,
		}


## Should not be used.
func to_json(_value, _ruleset:Dictionary) -> void:
	pass


func from_json(json:Dictionary, ruleset:Dictionary) -> Variant:
	var named_references = ruleset.get('property_reference_values',{})
	if named_references is not Dictionary:
		report_error(0)
		return null

	var ref_name:String = json.get('v','')
	if ref_name.is_empty():
		var type:StringName = json.get('.t', '')
		var split_type = type.split(':')
		# Throw error if invalid number of splits.
		if split_type.size() != 2:
			report_error(3)
			return null
		ref_name = split_type[1]

	# Handle object reference.
	if ref_name.is_valid_int():
		var ids_to_objects = A2J._process_data.get('ids_to_objects', {})
		if ids_to_objects is Dictionary:
			return ids_to_objects.get(ref_name, '_A2J_unresolved_reference')
	# Handle external resource reference.
	elif ref_name.begins_with('r:'):
		var path:String = ref_name.trim_prefix('r:')
		var resource = load(path)
		if resource == null:
			report_error(2, path)
		return resource

	return named_references.get(ref_name, null)
