extends PanelContainer

signal selected

@onready var options_popup:PopupMenu = %Options.get_popup()
var track: DBTrack


func _ready() -> void:
	options_popup.id_pressed.connect(_on_option_id_pressed)


func init(db_track:DBTrack) -> void:
	track = db_track
	if not track.valid: _invalidate()
	%Name.text = track.name
	%Artist.text = '%s - %s' % [track.artist.name, track.album.name]
	%'Track Number'.text = '%s' % (track.number+1)
	var track_length_remainder := int(fmod(track.length,60))
	%Length.text = '%s:%s' % [int(track.length/60), ('0' if track_length_remainder < 10 else '') + str(track_length_remainder)]
	%Format.text = '.%s' % track.path.split('.')[-1].to_lower()
	%Image.texture = track.album.cover


func _invalidate() -> void:
	self.hide()


func _on_button_pressed() -> void:
	selected.emit()


func _on_option_id_pressed(id:int) -> void:
	match id:
		0: pass
		1: PlayerManager.add_to_queue(track)
		3: OS.shell_show_in_file_manager(track.path)
		4: init(LibraryManager.rescan_track(track))
