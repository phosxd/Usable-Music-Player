extends Control

enum ColorSource {
	Accent,
	Text,
	TextPrimary,
	Background,
}

@export var color_source := ColorSource.Accent


func _ready() -> void:
	ThemeManager.theme_applied.connect(_on_theme_applied)
	_on_theme_applied()


func _on_theme_applied() -> void:
	match self.color_source:
		ColorSource.Accent:
			self.modulate = ThemeManager.accent_override_color
		ColorSource.Text:
			self.modulate = ThemeManager.text_color
		ColorSource.TextPrimary:
			self.modulate = ThemeManager.text_primary_color
		ColorSource.Background:
			self.modulate = ThemeManager.bg_color
