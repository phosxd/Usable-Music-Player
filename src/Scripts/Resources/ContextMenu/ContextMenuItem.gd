@tool
class_name ContextMenuItem extends Resource

enum ItemType {
	Button,
	SubMenu,
}

@export var type: ItemType:
	set(v):
		type = v
		notify_property_list_changed()

## Item ID.
@export var id: String

## Item display text.
@export var text: String

## Item display icon name.
@export var icon_name: StringName

#region Button

@export_category('Button')
## Whether or not the button is checkable.
@export var checkable:bool = false

#endregion
#region SubMenu

@export_category('SubMenu')
## SubMenu items.
@export var items: Array[ContextMenuItem]

#endregion


func _validate_property(property:Dictionary) -> void:
	match property.name:
		'checkable':
			if type != ItemType.Button: property.usage |= PROPERTY_USAGE_READ_ONLY
		'items':
			if type != ItemType.SubMenu: property.usage |= PROPERTY_USAGE_READ_ONLY
