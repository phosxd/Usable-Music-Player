## A simple logging utility for Godot 4.5 & above.
##
## Text can be easily formatted using these tags alongside usual BBCode:
## [br]- [b]$~ text ~$[/b] Mark as supressed (darkened).
## [br]- [b]$! text !$[/b] Mark as warning (yellow).
## [br]- [b]$!! text !!$[/b] Mark as important (red).
## [br]- [b]$i text i$[/b] Mark as informational (light-blue, monospaced).
##
class_name MiniLog extends RefCounted

## An Object's importance level.
enum Importance {
	None,
	Low,
	High,
	Core,
}
const pro_template:String = '[color=white][lb]Process[rb][/color] %s [color=linen]%s[/color]'
const info_template:String = '[color=yellow_green][lb]Info[rb][/color] %s [color=linen]%s[/color]'
const warn_template:String = '[color=gold][lb]Warn[rb][/color] %s [color=linen]%s[/color]'

const _format_map:Dictionary[String,Array] = {
	'~': ['[color=gray]', '[/color]'],
	'!': ['[color=gold]', '[/color]'],
	'!!': ['[color=red]', '[/color]'],
	'i': ['[color=cornflower_blue][code]', '[/code][/color]'],
}
const _importance_format_map:Array[Array] = [
	['$~', '~$'],
	['[color=dark_sea_green]', '[/color]'],
	['[color=sandy_brown]', '[/color]'],
	['[color=firebrick]', '[/color]'],
]

## Append a callable to one of the preset keys in this dictionary.
## This is a replacement for signals as they are not available for static classes.
static var signals:Dictionary[String,Array] = {
	'log_added': [],
	'logs_about_to_clear': [],
}

## Maximum number of logs before [param logs] is cleared to save memory.
## [param logs_about_to_clear] will be emitted before logs get cleared.
static var max_log_count:int = 5_000
## Every log that has been created.
static var logs := PackedStringArray([])


## Save all previous logs to a text file.
static func save(path:String='user://logs/MiniLog.log') -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()

	file.store_string('\n'.join(logs))
	file.close()
	return Error.OK


## Prints an unimportant process text. Use this for common reporting of tasks.
static func pro(text:String, source:Object) -> void:
	var l:String = _format_text(pro_template % [_source_as_text(source), text])
	_log(l)


## Prints an informational text. Use this to communicate potentially useful information.
static func info(text:String, source:Object) -> void:
	var l:String = _format_text(info_template % [_source_as_text(source), text])
	_log(l)


## Prints a warning text. Use this to communicate important information.
static func warn(text:String, source:Object) -> void:
	var l:String = _format_text(warn_template % [_source_as_text(source), text])
	_log(l)


static func _log(l:String) -> void:
	logs.append(l)
	print_rich(l)

	for callable in signals.log_added:
		if callable is Callable && callable.is_valid(): callable.call_deferred(l)
		else: signals.log_added.erase(callable)

	if logs.size() >= max_log_count:
		for callable in signals.logs_about_to_clear:
			if callable is Callable && callable.is_valid(): callable.call_deferred()
			else: signals.logs_about_to_clear.erase(callable)


## Formats the [param text] using the tokens & values provided in [param _format_map].
static func _format_text(text:String) -> String:
	for token:String in _format_map:
		var bbcode = _format_map[token]
		text = text.replace('$'+token, bbcode[0]).replace(token+'$', bbcode[1])

	return text


## Grab an appropiate name from the [param source] object.
## Returns "???" if no name could be found.
##
## If [param formatted] is true, will return a string with BBCode formatting applied.
static func _source_as_text(source:Object, formatted:bool=true) -> String:
	var name:String = ''
	if source is Script:
		name = source.get_global_name()
	elif source is Node:
		name = source.name

	if name.is_empty(): name = '???'

	if formatted:
		var importance = source.get('minilog_importance')
		if importance is not Importance: importance = Importance.None
		name = '('+_importance_format_map[importance][0] + name + _importance_format_map[importance][1]+')'

	return name
