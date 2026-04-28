extends PanelContainer

const idle_color := Color('3333ff')
const scan_color := Color("ffb332ff")
const idle_text:String = 'Idle'
const scan_text:String = 'Scanning'
const idle_value:String = '...'

var library: DBLibrary


func init(library_:DBLibrary) -> void:
	library = library_
	%'Library Name'.text = library.name
	%'Library Name'.tooltip_text = library.name
	library.scan_started.connect(_on_scan_started)
	library.scan_finished.connect(_on_scan_finished)
	library.scan_progress_changed.connect(_on_scan_progress_changed)
	if library.currently_updating: _on_scan_started()


func _on_scan_started() -> void:
	%Action.text = scan_text
	%Action.self_modulate = scan_color


func _on_scan_finished(_made_changes:bool) -> void:
	%Action.text = idle_text
	%Action.self_modulate = idle_color
	%Value.text = idle_value


func _on_scan_progress_changed(progress:int) -> void:
	%Value.text = str(progress)
