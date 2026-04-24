extends Control

signal closed

@onready var card_scene:PackedScene = SessionManager.get_layout_theme_scene('Main/activity_menu_card')

var cards:Array[Control] = []


func close() -> void:
	closed.emit()
	self.queue_free()


func _ready() -> void:
	%'No Activity Label'.hide()

	for library:DBLibrary in LibraryManager.libraries:
		var card:Control = card_scene.instantiate()
		card.init(library)
		$VBox.add_child(card)
		cards.append(card)

	if cards.size() == 0:
		%'No Activity Label'.show()
