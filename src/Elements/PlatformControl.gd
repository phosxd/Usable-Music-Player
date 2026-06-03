## Hides & disables itself if the platform it is running on does not match the specified [member platforms].
extends Control

enum SystemPlatform {
	Linux,
	Windows,
	MacOS,
	IOS,
	Android,
	Web,
}

@export var platforms: Array[SystemPlatform]


func _ready() -> void:
	var platform: SystemPlatform
	var platform_str:String = OS.get_name()
	if platform_str == 'Linux' or platform_str.ends_with('BSD'): platform = SystemPlatform.Linux
	elif platform_str == 'Windows': platform = SystemPlatform.Windows
	elif platform_str == 'macOS': platform = SystemPlatform.MacOS
	elif platform_str == 'iOS': platform = SystemPlatform.IOS
	elif platform_str == 'Android': platform = SystemPlatform.Android
	elif platform_str == 'Web': platform = SystemPlatform.Web

	if platform not in platforms:
		self.hide()
		self.process_mode = Node.PROCESS_MODE_DISABLED
