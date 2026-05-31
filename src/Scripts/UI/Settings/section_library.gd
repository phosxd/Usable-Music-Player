extends Control

@onready var library_item_local_scene:PackedScene = SessionManager.get_scene('Settings/Library Item Local')
@onready var library_item_navidrome_scene:PackedScene = SessionManager.get_scene('Settings/Library Item Navidrome')


func _ready() -> void:
	var add_library_popup:PopupMenu = %'Add Library'.get_popup()
	add_library_popup.index_pressed.connect(_on_add_library_index_pressed)
	for library:DBLibrary in LibraryManager.libraries:
		if not library: continue
		match library.type:
			DBLibrary.LibraryType.LocalDirectory: add_local_library(library)
			#SessionManager.LibraryType.NavidromeServer: add_navidrome_library(item_data, false)


func _on_add_library_index_pressed(index:int) -> void:
	match index:
		0:
			var library := DBLibrary.new()
			library.type = DBLibrary.LibraryType.LocalDirectory
			library.id = DBLibrary._generate_id()
			library.name = 'New Library'
			SessionManager.get_var('visible_libraries').append(library.id)
			LibraryManager.libraries.append(library)
			add_local_library(library)
		1:
			pass#add_navidrome_library()


func add_local_library(library:DBLibrary) -> void:
	var item:Control = library_item_local_scene.instantiate()
	item.init(library)
	item.update_requested.connect(_library_item_updated.bind(library))
	item.move_requested.connect(_library_item_moved.bind(item, library))
	item.remove_requested.connect(_library_item_removed.bind(item, library))
	item.scan_requested.connect(_library_item_scanned.bind(item, library))
	%Libraries.add_child(item)


#func add_navidrome_library(data:Array=[SessionManager.LibraryType.NavidromeServer,'','',''], add_entry:bool=true) -> void:
	#var item_data:Array = data
	#if add_entry: SessionManager.libraries.append(item_data)
#
	#var item:Control = library_item_navidrome_scene.instantiate()
	#item.init(item_data)
	#item.update_requested.connect(_library_item_updated.bind(item_data))
	##var host_url = data[0]
	##var username = data[1]
	##var password = data[2]
	##var pass_salt:String = ''
	##for i in 6:
		##pass_salt += str(randi_range(0,9))
	##var token:String = (password+pass_salt).md5_text()
	##var request_url:String = host_url+'/rest/getAlbumList?f=json&v=1.16.1&c=test&u=%s&t=%s&s=%s&type=alphabeticalByName' % [username, token, pass_salt]
	##var client := HTTPRequest.new()
	##SessionManager.add_child(client)
	##var err:Error = client.request(request_url, [], HTTPClient.METHOD_GET)
	##if err != OK:
		##return
	##var response = await client.request_completed
	##var bytes:PackedByteArray = response[3]
	#item.move_requested.connect(_library_item_moved.bind(item, item_data))
	#item.remove_requested.connect(_library_item_removed.bind(item, item_data))
	#%Libraries.add_child(item)


func _library_item_updated(data:Array, library:DBLibrary) -> void:
	library.name = data[0]
	library.path = data[1]


func _library_item_moved(up:bool, item:Control, library:DBLibrary) -> void:
	var item_index:int = LibraryManager.libraries.find(library)
	if item_index == -1: return
	item_index += -1 if up else 1
	if item_index < 0 or item_index >= LibraryManager.libraries.size(): return
	LibraryManager.libraries.erase(library)
	LibraryManager.libraries.insert(item_index, library)
	%Libraries.move_child(item, item.get_index() + (-1 if up else 1))


func _library_item_removed(item:Control, library:DBLibrary) -> void:
	library.remove()
	item.queue_free()


func _library_item_scanned(_item:Control, library:DBLibrary) -> void:
	library.refresh()
