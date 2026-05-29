class_name TRESTools extends Object


## Replaces [param a] with [param b] in [param file] if the file is text-based.
static func replace_substr(file:FileAccess, a:String, b:String) -> void:
	# Get file text.
	var text:String = file.get_as_text()
	if text.is_empty(): return

	# Modify file text.
	text = text.replace(a, b)

	# Write file with changes.
	var file_write = FileAccess.open(file.get_path(), FileAccess.WRITE)
	file_write.store_string(text)
	file_write.close()


## Resets all UIDs in [param file] if file is text-based.
## This works by replacing all UIDs in the file with an invalid value which Godot should automatically replace using the sub-res path upon saving.
static func reset_uids(file:FileAccess) -> void:
	# Get file text.
	var text:String = file.get_as_text()
	if text.is_empty(): return

	var pos:int = 0
	const key:String = 'uid="uid://'
	var key_length:int = key.length()
	while true:
		var uid_begin:int = text.find(key, pos)
		if uid_begin <= pos: break # Stop looking for UIDs if we already went through them all.
		pos = uid_begin+key_length
		var uid_end:int = text.find('"', uid_begin+key_length)
		text = text.erase(uid_begin+key_length, (uid_end-uid_begin)-key_length) # Remove old UID value.
		text = text.insert(uid_begin+key_length, '000000') # Add invalid UID.

	# Write file with changes.
	var file_write = FileAccess.open(file.get_path(), FileAccess.WRITE)
	file_write.store_string(text)
	file_write.close()
