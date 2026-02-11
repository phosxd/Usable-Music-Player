extends PanelContainer

signal selected


func init(track_name:String, track_length:float, album_name:String, artist_name:String, cover:ImageTexture) -> void:
	%Name.text = track_name
	%Artist.text = '%s - %s' % [artist_name, album_name]
	var track_length_remainder := int(fmod(track_length,60))
	%Length.text = '%s:%s' % [int(track_length/60), ('0' if track_length_remainder < 10 else '') + str(track_length_remainder)]
	if cover:
		%Image.texture = cover


func _on_button_pressed() -> void:
	selected.emit()
