extends Control

const import_config_scene:PackedScene = preload('res://Scenes/Dialogs/Import Config/scene.tscn')
const export_config_scene:PackedScene = preload('res://Scenes/Dialogs/Export Config/scene.tscn')
@onready var export_config_popup:PopupMenu = %'Export Config'.get_popup()


func _ready() -> void:
	var index:int = export_config_popup.item_count
	for item in SessionManager.sections:
		export_config_popup.add_check_item(item[0])
		export_config_popup.set_item_checked(index, true)
		index += 1
	export_config_popup.index_pressed.connect(_on_export_config_index_pressed)


func _on_import_config_pressed() -> void:
	var popup:FileDialog = import_config_scene.instantiate()
	popup.file_selected.connect(func(path:String) -> void:
		SessionManager.import_config(path)
	)
	popup.show()
	


func _on_export_config_index_pressed(index:int) -> void:
	if index == 0:
		var popup:FileDialog = export_config_scene.instantiate()
		popup.file_selected.connect(func(path:String) -> void:
			var sections:Array[String] = []
			for index_2:int in export_config_popup.item_count:
				if index_2 == 0: continue
				if export_config_popup.is_item_checked(index_2):
					sections.append(SessionManager.sections[index_2-1][0])
			SessionManager.export_config(path, sections)
		)
		popup.show()
	else:
		export_config_popup.toggle_item_checked(index)
