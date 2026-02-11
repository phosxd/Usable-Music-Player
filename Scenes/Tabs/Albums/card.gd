extends PanelContainer

signal selected


func init(album_name:String, artist_name:String, cover:ImageTexture) -> void:
	%Name.text = album_name
	%Artist.text = artist_name
	if cover:
		%Image.texture = cover


func _on_button_pressed() -> void:
	selected.emit()
