class_name StringUtils extends RefCounted

const months:PackedStringArray = [
	'January',
	'Feburary',
	'March',
	'April',
	'May',
	'June',
	'July',
	'August',
	'September',
	'October',
	'November',
	'December',
]

const ordinal_suffixes:Dictionary[String,String] = {
	'1': 'st',
	'2': 'nd',
	'3': 'rd',
	'4+': 'th',
	'0': 'th',
	'11': 'th',
}


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


## Returns the number in ordinal form. E.g. "1st", "2nd", "3rd", "112th".
static func get_ordinal_number(number:int) -> String:
	var text:String = str(number)
	var suffix: String

	if number == 0: pass
	elif abs(number) == 1: suffix = ordinal_suffixes['11']
	elif text.ends_with('1'): suffix = ordinal_suffixes['1']
	elif text.ends_with('2'): suffix = ordinal_suffixes['2']
	elif text.ends_with('3'): suffix = ordinal_suffixes['3']
	elif abs(number) > 3 && abs(number) < 10: suffix = ordinal_suffixes['4+']
	elif text.ends_with('0'): suffix = ordinal_suffixes['0']

	return text+suffix


## Get readble date from YYYY/MM/DD date. Example result "January 1st 2000".
## Returns an empty string if failed.
static func get_readable_date(text:String) -> String:
	var split:PackedStringArray = text.replace('-','/').replace(' ','/').split('/', false)
	if split.size() != 3: return ''
	return '%s %s %s' % [
		months.get(int(split[1])-1),
		get_ordinal_number(int(split[2])),
		split[0],
	]
