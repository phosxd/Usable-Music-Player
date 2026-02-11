extends Control

const dir_open_popup := preload('res://Scenes/Dir Open/dir_open.tscn')
const info_popup := preload('res://Scenes/Info Popup/info_popup.tscn')
@onready var info_text_template:String = %Info.text


func _ready() -> void:
	update()


func update() -> void:
	@warning_ignore('integer_division')
	%Info.text = String(info_text_template) % [
		LibraryManager.db_cache_size_compressed/1000/1000,
		LibraryManager.db_cache_size/1000/1000,
		LibraryManager.database.get('timestamp', 'Never'),
		LibraryManager.library_size/1000/1000,
		LibraryManager.library_track_count,
	]
	%'Library Path'.text = LibraryManager.database.location


func _on_select_library_pressed() -> void:
	@warning_ignore('shadowed_variable_base_class')
	var popup:FileDialog = dir_open_popup.instantiate()
	popup.dir_selected.connect(func(path:String) -> void:
		_on_library_path_text_changed(path)
	)
	self.add_child(popup)
	popup.show()


func _on_library_path_text_changed(new_text:String) -> void:
	@warning_ignore('shadowed_variable_base_class')
	var popup:AcceptDialog = info_popup.instantiate()
	popup.dialog_text = 'Please wait while indexing files. This may take some time depending on your system\'s capability & the library size.\n\nThe app is frozen during indexing, this is intended. Once indexing has finished this popup will close & the app will resume.'
	self.add_child(popup)
	get_tree().create_timer(0.1).timeout.connect(func() -> void:
		LibraryManager.load_library(new_text)
		%'Library Path'.text = new_text
		update()
		popup.queue_free()
	)


func _on_rescan_library_pressed() -> void:
	_on_library_path_text_changed(%'Library Path'.text)


func _on_user_data_pressed() -> void:
	OS.shell_open(OS.get_user_data_dir())


func _on_source_code_pressed() -> void:
	OS.shell_open(AppInfo.source_code)


func _on_report_issue_pressed() -> void:
	OS.shell_open(AppInfo.issues_page)
