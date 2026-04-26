## Handles serialization for various types.
## [br][br][b]Types:[/b]
## [br]- StringName
## [br]- NodePath
## [br]- Color
## [br]- Plane
## [br]- Quaternion
## [br]- Rect2
## [br]- Rect2i
## [br]- AABB
## [br]- Basis
## [br]- Transform2D
## [br]- Transform3D
## [br]- Projection
class_name A2JMiscTypeHandler extends A2JTypeHandler


func _init() -> void:
	error_strings = [
		'Cannot convert invalid value to JSON.',
		'Cannot construct value from invalid JSON representation.',
	]


func to_json(v, ruleset:Dictionary) -> Dictionary[String,Variant]:
	var result:Dictionary[String,Variant] = {
		'.t': type_string(typeof(v)),
		'v': null,
	}

	if v is StringName or v is NodePath:
		result.v = str(v)
	elif v is Color:
		result.v = A2JUtil.to_snapped_array([v.r, v.g, v.b, v.a], 0.00001) # Limit to 5 decimals.
	elif v is Plane:
		result.v = [v.x, v.y, v.z, v.d]
	elif v is Quaternion:
		result.v = [v.x, v.y, v.z, v.w]
	elif v is Rect2 or v is Rect2i:
		result.v = [v.position.x, v.position.y, v.size.x, v.size.y]
	elif v is AABB:
		result.v = [
			v.position.x, v.position.y, v.position.z,
			v.size.x, v.size.y, v.size.z,
		]
	elif v is Basis:
		result.v = [
			v.x.x, v.x.y, v.x.z,
			v.y.x, v.y.y, v.y.z,
			v.z.x, v.z.y, v.z.z,
		]
	elif v is Transform2D:
		result.v = [
			v.x.x, v.x.y,
			v.y.x, v.y.y,
			v.origin.x, v.origin.y,
		]
	elif v is Transform3D:
		result.v = [
			v.basis.x.x, v.basis.x.y, v.basis.x.z,
			v.basis.y.x, v.basis.y.y, v.basis.y.z,
			v.basis.z.x, v.basis.z.y, v.basis.z.z,
			v.origin.x, v.origin.y, v.origin.z,
		]
	elif v is Projection:
		result.v = [
			v.x.x, v.x.y, v.x.z, v.x.w,
			v.y.x, v.y.y, v.y.z, v.y.w,
			v.z.x, v.z.y, v.z.z, v.z.w,
			v.w.x, v.w.y, v.w.z, v.w.w,
		]

	# Throw error if not an expected type.
	else:
		report_error(0)
		return {}

	return result


func from_json(headers:PackedStringArray, json:Dictionary, ruleset:Dictionary) -> Variant:
	var type:String = headers[0]
	var v = json.get('v')

	match type:
		'StringName':
			if v is not String: report_error(1); return null
			return StringName(v)
		'NodePath':
			if v is not String: report_error(1); return null
			return NodePath(v)
		'Color':
			if v is not Array or v.size() != 4: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Color(v[0], v[1], v[2], v[3])
		'Plane':
			if v is not Array or v.size() != 4: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Plane(Vector3(v[0], v[1], v[2]), v[3])
		'Quaternion':
			if v is not Array or v.size() != 4: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Quaternion(v[0], v[1], v[2], v[3])
		'Rect2':
			if v is not Array or v.size() != 4: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Rect2(v[0], v[1], v[2], v[3])
		'Rect2i':
			if v is not Array or v.size() != 4: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3]))
		'AABB':
			if v is not Array or v.size() != 6: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return AABB(Vector3(v[0], v[1], v[2]), Vector3(v[3], v[4], v[5]))
		'Basis':
			if v is not Array or v.size() != 9: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Basis(
				Vector3(v[0], v[1], v[2]),
				Vector3(v[3], v[4], v[5]),
				Vector3(v[6], v[7], v[8]),
			)
		'Transform2D':
			if v is not Array or v.size() != 6: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Transform2D(
				Vector2(v[0], v[1]),
				Vector2(v[2], v[3]),
				Vector2(v[4], v[5]),
			)
		'Transform3D':
			if v is not Array or v.size() != 12: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Transform3D(
				Vector3(v[0], v[1], v[2]),
				Vector3(v[3], v[4], v[5]),
				Vector3(v[6], v[7], v[8]),
				Vector3(v[9], v[10], v[11]),
			)
		'Projection':
			if v is not Array or v.size() != 16: report_error(1); return null
			if not A2JUtil.is_number_array(v): report_error(1); return null
			return Projection(
				Vector4(v[0], v[1], v[2], v[3]),
				Vector4(v[4], v[5], v[6], v[7]),
				Vector4(v[8], v[9], v[10], v[11]),
				Vector4(v[12], v[13], v[14], v[15]),
			)

	# Throw error if no conditions match.
	report_error(1)
	return null
