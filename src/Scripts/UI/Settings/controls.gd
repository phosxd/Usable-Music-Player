extends Control

const import_config_scene:PackedScene = preload('res://Scenes/Dialogs/Import Config/scene.tscn')
const export_config_scene:PackedScene = preload('res://Scenes/Dialogs/Export Config/scene.tscn')
@onready var export_config_popup:PopupMenu = %'Export Config'.get_popup()

var export_config_values:Array[String] = []


func _ready() -> void:
	export_config_values.clear()
	export_config_popup.add_separator()
	for item in SessionManager.sections:
		export_config_popup.add_item(item[0])
		export_config_values.append(item[0])
	export_config_popup.index_pressed.connect(_on_export_config_index_pressed)


func _on_import_config_pressed() -> void:
	var popup:FileDialog = import_config_scene.instantiate()
	popup.file_selected.connect(func(path:String) -> void:
		SessionManager.import_config(path)
	)
	popup.show()
	


func _on_export_config_index_pressed(index:int) -> void:
	var popup:FileDialog = export_config_scene.instantiate()
	popup.file_selected.connect(func(path:String) -> void:
		if index == 0:
			SessionManager.export_config(path, export_config_values)
		else:
			var section:String = export_config_values[index-2]
			SessionManager.export_config(path, [section])
	)
	popup.show()
