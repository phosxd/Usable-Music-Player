class_name A2JReferenceTypeHandler extends A2JTypeHandler


func _init() -> void:
	error_strings = [
		'"references" in ruleset should be structured as follows: Dictionary[String,Variant].',
		'Could not load referenced resource at "%s".',
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


func from_json(headers:PackedStringArray, json:Dictionary, ruleset:Dictionary) -> Variant:
	var named_references = ruleset.get('property_reference_values',{})
	if named_references is not Dictionary:
		report_error(0)
		return null

	var ref_name:String = json.get('v','')
	if ref_name.is_empty():
		# Throw error if invalid number of headers.
		if headers.size() != 2:
			report_error(3)
			return null
		ref_name = headers[1]
		# Throw error if reference id is invalid.
		if not ref_name.is_valid_int():
			report_error(3)
			return null

	# Handle variant reference.
	if ref_name.is_valid_int():
		var variant_map = A2J._process_data.get('variant_map', {})
		if variant_map is Dictionary:
			return variant_map.get(ref_name.to_int(), '_A2J_unresolved_reference')

	# Handle external resource reference.
	elif ref_name.begins_with('r:'):
		var path:String = ref_name.trim_prefix('r:')
		var resource = load(path)
		if resource == null:
			report_error(2, path)
		return resource

	return named_references.get(ref_name, null)
