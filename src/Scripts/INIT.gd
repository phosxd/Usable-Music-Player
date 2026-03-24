extends Node

const icon:Texture2D = preload('res://icon.svg')
const desktop_file_name:String = 'SOHP Usable Music Player.desktop'
const desktop_file_data:String = """
[Desktop Entry]
Type=Application
Exec='%s'
Name=%s
Icon=%s
Categories=Application;Player;Media
"""

@onready var icon_file_path:String = OS.get_user_data_dir()+'/icon.png'
@onready var desktop_file_path:String = OS.get_user_data_dir()+'/'+desktop_file_name


func _ready() -> void:
	# Save icon to user data.
	icon.get_image().save_png(icon_file_path)
	# Set up desktop file.
	if OS.get_name() == 'Linux' && not OS.has_feature('editor'): generate_desktop_file()

	# Load library database.
	LibraryManager.load_database()


## Generates & saves a Linux desktop file for this app.
func generate_desktop_file() -> void:
	MiniLog.info('Generating Linux desktop file.', self)
	var file := FileAccess.open(desktop_file_path, FileAccess.WRITE)
	if not file: return
	file.store_string(desktop_file_data % [
		OS.get_executable_path(),
		ProjectSettings.get_setting('application/config/name'),
		icon_file_path,
	])
	file.close()

	# Get user's name.
	var output:Array = []
	var _error = OS.execute('whoami', [], output, true)
	var username = output.get(0)
	if username is not String:
		printerr('Could not find current user on this Linux machine. Skipping desktop integration.')
		return
	username = (username as String).replace('\n','')

	var apps_path:String = '/home/%s/.local/share/applications' % username
	DirAccess.make_dir_recursive_absolute(apps_path)
	DirAccess.copy_absolute(desktop_file_path, apps_path+'/'+desktop_file_name)
