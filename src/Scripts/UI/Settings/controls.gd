extends Control

const import_config_scene:PackedScene = preload('res://Scenes/Dialogs/Import Config/scene.tscn')
const export_config_scene:PackedScene = preload('res://Scenes/Dialogs/Export Config/scene.tscn')
@onready var export_config_popup:PopupMenu = %'Export Config'.get_popup()

var export_config_values:Array[String] = []


func _ready() -> void:
	export_config_values.clear()
	export_config_popup.add_separator()
	for item in SessionManager.get_var('sections'):
		export_config_popup.add_item(item[0])
		export_config_values.append(item[0])
	export_config_popup.index_pressed.connect(_on_export_config_index_pressed)
	update_user_data_text()


func update_user_data_text() -> void:
	@warning_ignore('integer_division')
	%'User Data'.text = 'User Data (%s MiB)' % int(LibraryManager.get_user_data_size()/1048_000)


func _on_import_config_pressed() -> void:
	var popup:FileDialog = import_config_scene.instantiate()
	popup.file_selected.connect(func(path:String) -> void:
		SessionManager.import_config(path)
	)
	popup.show()
	


func _on_export_config_index_pressed(index:int) -> void:
	var popup:FileDialog = export_config_scene.instantiate()
	popup.current_file = 'new_config.json'
	popup.file_selected.connect(func(path:String) -> void:
		if index == 0:
			SessionManager.export_config(path, export_config_values)
		else:
			var section:String = export_config_values[index-2]
			SessionManager.export_config(path, [section])
	)
	popup.show()


func _on_refresh_user_data_size_pressed() -> void:
	LibraryManager.refresh_user_data_size()
	update_user_data_text()
