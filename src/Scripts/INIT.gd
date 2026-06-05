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


func _init() -> void:
	TesseractErrorServer.info.connect(_on_tes_info)
	TesseractErrorServer.warning.connect(_on_tes_warning)
	TesseractErrorServer.error.connect(_on_tes_error)
	
	TesseractAPI.load_mods()
	for mod:TesseractMod in TesseractAPI.mod_instances.values():
		MiniLog.info('Loaded mod "$i%si$".' % mod.id, self)


func _on_tes_info(code:int, translations:Array) -> void:
	MiniLog.info(TesseractErrorServer.info_strings[code] % translations, self)


func _on_tes_warning(code:int, translations:Array) -> void:
	MiniLog.warn(TesseractErrorServer.warning_strings[code] % translations, self)


func _on_tes_error(code:int, translations:Array) -> void:
	MiniLog.err(TesseractErrorServer.error_strings[code] % translations, self)


func _ready() -> void:
	get_window().min_size = Vector2i(800,500)
	# Save icon to user data.
	icon.get_image().save_png(icon_file_path)
	# Set up desktop file.
	if OS.get_name() == 'Linux' && not OS.has_feature('editor'): generate_desktop_file()

	# Initialize MPRIS server.
	PyInterface.update_mpris_data({
		'app_name': AppInfo.name,
		'desktop_entry': desktop_file_path,
	})


## Generates & saves a Linux desktop file for this app.
func generate_desktop_file() -> void:
	MiniLog.info('Generating Linux desktop file.', INIT)
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
