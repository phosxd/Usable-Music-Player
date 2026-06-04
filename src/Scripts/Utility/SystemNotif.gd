class_name SystemNotif extends RefCounted

enum Urgency {
	Low,
	Normal,
	High,
}
const urgency_string_map:Dictionary[Urgency,String] = {
	Urgency.Low: 'low',
	Urgency.Normal: 'normal',
	Urgency.High: 'critical',
}


## Sends a system notification intended for the user to see.
static func send(title:String, body:String, urgency:=Urgency.Low, icon_path:String='', expire_time:float=3.25) -> int:
	print(str(int(expire_time*1000.0)))
	match OS.get_name():
		'Linux':
			return OS.execute('notify-send', [
				'-a', AppInfo.name, # App name.
				title.replace('"','\\"'), # Title text.
				body.replace('"','\\"'), # Body text.
				'-u', urgency_string_map[urgency],
				'-i', icon_path.replace('"','\\"'), # Icon.
				'-t', str(int(expire_time*1000.0)), # Expire time (ms).
			])

	return Error.OK
