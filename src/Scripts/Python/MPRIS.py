import asyncio
import random
from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, dbus_method, dbus_property, dbus_signal
from dbus_fast import Variant, PropertyAccess

mpris_obj_path:str = '/org/mpris/MediaPlayer2'
player_name:str = 'sohp_ump.a'+str(random.randint(10000,99999))
bus:MessageBus = None

# Map data properties to their interface properties.
data_key_to_interface_property_map:dict[str,str] = {
	'track_title': '2/Metadata',
	'track_album': '2/Metadata',
	'track_artist': '2/Metadata',
	'track_length': '2/Metadata',
	'track_position': '2/Position',
	'playback_status': '2/PlaybackStatus',
	'volume': '2/Volume',
	'art_url': '2/Metadata',
	'lyrics': '2/Metadata',
	'lyrics_synced': '2/Metadata',
	'app_name': '1/Identity',
	'desktop_entry': '1/DesktopEntry',
}

data:dict[str,any] = {
	'track_title': '',
	'track_album': '',
	'track_artist': '',
	'track_length': 0,
	'track_position': 0,
	'playback_status': 'Paused',
	'volume': 0,
	'art_url': '',
	'lyrics': '',
	'lyrics_synced': '',
	'app_name': 'Placeholder Name',
	'desktop_entry': '',
}

events:list[dict] = []


def command_get_events(args:list):
	events_copy = list(events)
	events.clear()
	return events_copy


def command_update_data(args:list):
	properties_to_emit_changed:dict[str,any] = {}

	# Get arguments & assign to data.
	for arg in args:
		arg_type = arg['type']
		arg_value = arg['value']
		if arg_type in data.keys():
			data[arg_type] = arg_value
			properties_to_emit_changed[data_key_to_interface_property_map[arg_type]] = arg_value

	# Emit properties changed for each interface that has data changed.
	for interface_id in interfaces.keys():
		interface:ServiceInterface = interfaces[interface_id]
		interface_properties_to_emit_changed:dict[str,any] = {}
		# Sort through changed properties, find only the ones belonging to this interface.
		for key in properties_to_emit_changed.keys():
			property_value = properties_to_emit_changed[key]
			split_key = key.split('/')
			# Get details.
			interface_id_ = split_key[0]
			property_name = split_key[1]
			if interface_id_ == interface_id:
				if property_name == 'Metadata': property_value = interfaces['2'].Metadata
				elif property_name == 'Position' and (type(property_value) is float or type(property_value) is int): property_value = int(property_value)*1000000
				elif property_name == 'Volume' and type(property_value) is float: property_value = int(property_value)
				interface_properties_to_emit_changed[property_name] = property_value
		# If properties have changed, emit changes.
		if len(interface_properties_to_emit_changed) == 0: continue
		interface.emit_properties_changed(changed_properties=interface_properties_to_emit_changed.copy())


	return




# Primary MPRIS interface.
class MediaPlayer2Interface(ServiceInterface):
	def __init__(self, name: str):
		super().__init__(name)


	@dbus_method()
	def Quit(self):
		events.append({
			'type': 'quit',
		})


	@dbus_method()
	def Raise(self):
		pass


	@dbus_property(access=PropertyAccess.READ)
	def CanQuit(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def CanRaise(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def HasTrackList(self) -> 'b':
		return False

	@dbus_property(access=PropertyAccess.READ)
	def SupportedMimeTypes(self) -> 'as':
		return ['audio/']

	@dbus_property(access=PropertyAccess.READ)
	def SupportedUriSchemes(self) -> 'as':
		return ['file']

	@dbus_property(access=PropertyAccess.READ)
	def DesktopEntry(self) -> 's':
		return data['desktop_entry']

	@dbus_property(access=PropertyAccess.READ)
	def Identity(self) -> 's':
		return data['app_name']




# MPRIS player interface.
class PlayerInterface(ServiceInterface):
	def __init__(self, name: str):
		super().__init__(name)


	@dbus_method()
	def Play(self):
		events.append({
			'type': 'set_playing',
			'value': True,
		})


	@dbus_method()
	def Pause(self):
		events.append({
			'type': 'set_playing',
			'value': False,
		})


	@dbus_method()
	def PlayPause(self):
		events.append({
			'type': 'set_playing',
			'value': None,
		})


	@dbus_method()
	def Previous(self):
		events.append({
			'type': 'skip_backward',
		})


	@dbus_method()
	def Next(self):
		events.append({
			'type': 'skip_forward',
		})


	@dbus_method()
	def Seek(self, offset:'x'): # x = Int64
		events.append({
			'type': 'add_position',
			'value': float(offset)/1000000, # Convert offset to seconds.
		})


	@dbus_method()
	def SetPosition(self, trackId:'o', position:'x'):
		events.append({
			'type': 'set_position',
			'value': float(position)/1000000,
		})


	@dbus_property(access=PropertyAccess.READWRITE)
	def Rate(self) -> 'd': # Double
		return 1.0 # Always playback at rate of 1.0x

	@Rate.setter
	def set_rate(self, value:'d'): # Ignore rate setting.
		pass

	@dbus_property(access=PropertyAccess.READWRITE)
	def Volume(self) -> 'd': # Double
		return data['volume']

	@Volume.setter
	def set_volume(self, value:'d'):
		events.append({
			'type': 'set_volume',
			'value': value,
		})

	@dbus_property(access=PropertyAccess.READ)
	def CanControl(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def CanPlay(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def CanPause(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def CanGoPrevious(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def CanGoNext(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def CanSeek(self) -> 'b':
		return True

	@dbus_property(access=PropertyAccess.READ)
	def Position(self) -> 'x': # Int64
		return int(data['track_position'])*1000000

	@dbus_property(access=PropertyAccess.READ)
	def PlaybackStatus(self) -> 's':
		return data['playback_status']

	@dbus_property(access=PropertyAccess.READ)
	def Metadata(self) -> 'a{sv}':
		return {
			'mpris:trackid': Variant('o', '/org/mpris/MediaPlayer2/TrackList/Track'),
			'mpris:length': Variant('d', int(data['track_length'])*1000000),
			'xesam:title': Variant('s', data['track_title']),
			'xesam:album': Variant('s', data['track_album']),
			'xesam:artist': Variant('s', data['track_artist']),
			'mpris:artUrl': Variant('s', data['art_url']),
			'extra:lyrics': Variant('s', data['lyrics']),
			'extra:lyricsSynced': Variant('s', data['lyrics_synced']),
		}




interfaces = {
	'1': MediaPlayer2Interface('org.mpris.MediaPlayer2'),
	'2': PlayerInterface('org.mpris.MediaPlayer2.Player'),
}


def start():
	try:
		asyncio.run(_start())
	finally:
		pass


def quit():
	bus.disconnect()


async def _start():
	global bus
	bus = await MessageBus().connect()
	# Export interfaces.
	for interface in interfaces.values():
		bus.export(mpris_obj_path, interface)
	# Request name.
	await bus.request_name(f'org.mpris.MediaPlayer2.{player_name}')
	# Hold thread until bus disconnect.
	await bus.wait_for_disconnect()


if __name__ == "__main__":
	start()
