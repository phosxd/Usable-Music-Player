class_name StringUtils extends RefCounted


## Returns [code]true[/code] if [param a] is fuzzily found inside [param b].
static func fuzzy_match(a:String, b:String) -> bool:
	return a.to_lower().replace(' ','').is_subsequence_ofn(b.to_lower().replace(' ',''))


static func fuzzify(text:String) -> String:
	return text.to_lower().replace(' ','').replace('/','').replace('_','')
