extends Window

const help_text:String = """
$!Tips:
_______!$

- $iWe use GD Expressions!i$
: $~Visit: https://docs.godotengine.org/en/stable/classes/class_expression.html~$
: $~Visit: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html~$

- $iTry ".call" to call functions & methods if standard syntax doesn't work.i$

- $iYou can evaluate mathematical expressions.i$

- $iYou can format & concat strings.i$


$!Media Controls:
_________________!$

- $iPlayer.set_playing(playing:bool) -> voidi$
: $~Set current track playing state.~$

- $iPlayer.previous() -> voidi$
: $~Skip to the previous track in the queue.~$

- $iPlayer.next() -> voidi$
: $~Skip to the next track in the queue.~$

- $iPlayer.set_track_progress(progress:float) -> voidi$
: $~Set current track play progress.~$


$!Python Commands:
__________________!$

- $iPy.send_command(command:String, args:=PackedStringArray()) -> Dictionaryi$
: $~Send a command to the Python interface.~$


$!Useful Tools:
_______________!$

- $iobj_info(obj:Object) -> Stringi$
: $~Retrieve all available properties & methods for the object in a read-able form.~$
"""

var expression := Expression.new()


func _ready() -> void:
	%Label.text = '\n'.join(MiniLog.logs)
	MiniLog.signals.log_added.append(_on_log_added)


## Get all properties & methods belonging to [param obj] then return in a [MiniLog] formatted string.
func obj_info(obj:Object) -> String:
	var result := PackedStringArray(['$!!%s!!$\n$!Properties:\n_____________!$\n' % obj])

	# Get properties.
	var properties:Array[Dictionary] = obj.get_property_list()
	for prop:Dictionary in properties:
		result.append('- $i%si$$~: %s =~$ %s' % [
			prop.name,
			type_string(prop.type),
			obj.get(prop.name),
		])

	# Get methods.
	result.append(('\n$!Methods:\n__________!$\n').dedent())
	var methods:Array[Dictionary] = obj.get_method_list()
	for method:Dictionary in methods:
		# Unpack arguments.
		var args_unpacked := PackedStringArray()
		for arg:Dictionary in method.args:
			args_unpacked.append('%s$~:%s~$' % [arg.name, type_string(arg.type)])
		# Add method.
		result.append('- $i%si$$~(~$%s$~)~$ -> $~%s~$' % [
			method.name,
			'$~,~$ '.join(args_unpacked),
			type_string(method.return.type)
		])

	return '\n'.join(result)


func _on_log_added(text:String='') -> void:
	%Label.append_text('\n'+text)


func _on_command_text_submitted(command:String) -> void:
	%Command.text = ''
	var parse_err:Error = expression.parse(command, [
		'help',
		'obj_info',
		'Session',
		'Library',
		'Player',
		'Theme',
		'Request',
		'Shortcut',
		'Dialog',
		'Py',
	])
	if parse_err != OK:
		MiniLog.err('Failed to parse expression with error "$!!%s!!$".' % expression.get_error_text(), self)
		return

	var result = expression.execute([
		help_text,
		obj_info,
		SessionManager,
		LibraryManager,
		PlayerManager,
		ThemeManager,
		RequestManager,
		ShortcutManager,
		DialogManager,
		PyInterface,
	], Object.new(), false)
	# Print error.
	if expression.has_execute_failed():
		MiniLog.err('Failed to execute expression with error "$!!%s!!$".' % expression.get_error_text(), self)
		return
	# Print result.
	MiniLog.info(str(result), self)


func _on_close_requested() -> void:
	self.queue_free()
