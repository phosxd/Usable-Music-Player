class_name StringUtils extends RefCounted


## Returns [code]true[/code] if [param a] is fuzzily found inside [param b].
static func fuzzy_match(a:String, b:String) -> bool:
	return a.to_lower().replace(' ','').is_subsequence_ofn(b.to_lower().replace(' ',''))


static func fuzzify(text:String) -> String:
	return text.to_lower().replace(' ','').replace('/','').replace('_','')


## Ensures [param target] is unique among the [param pool] by adding an incrementing number at the end if needed.
static func resolve_duplicate(target:String, pool:PackedStringArray) -> String:
	if target in pool:
		var number = target[-1]
		if not number.is_valid_int(): number = 0
		else:
			target = target.erase(target.length()-1)
			number = int(number)
		number += 1
		target = target+str(number)
		
	if target in pool: target = resolve_duplicate(target, pool)
	return target
