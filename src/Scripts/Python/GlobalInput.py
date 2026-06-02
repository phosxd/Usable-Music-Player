# Record keyboard inputs & return them when needed with "command_get_global_input".
# For security reasons on Linux, alphaneumeric keys can only be captured when CTRL, META, or ALT keys are also pressed.
from pynput.keyboard import Key, Listener
import json


modifier_shift = False
modifier_ctrl = False
modifier_alt = False
modifier_meta = False

input_log = []

response_template = {
	'cmd': 'GlobalInput',
	'id': '0',
	'data': None,
}


def command_get_global_input(args):
	input_log_copy = list(input_log)
	input_log.clear()
	return input_log_copy


def get_key_string(key):
	key_string = ''

	# Add modifiers to key string.
	if modifier_shift: key_string += 'Shift+'
	if modifier_ctrl: key_string += 'Ctrl+'
	if modifier_alt: key_string += 'Alt+'
	if modifier_meta: key_string += 'Meta+'
	try:
		char = key.char.upper()
		char = char \
			.replace('{','[').replace('}',']') \
			.replace('[','LeftBracket').replace(']','RightBracket') \
			.replace('|','\\').replace('\\','BackSlash') \
			.replace(';','Semicolon') \
			.replace('"','\'').replace('\'','Apostrophe') \
			.replace('<',',').replace(',','Comma') \
			.replace('>','.').replace('.','Period') \
			.replace('?','/').replace('/','Slash')
		key_string += char
	except:
		if key == Key.num_lock: key_string += 'NumLock'
		elif key in [Key.page_up, Key.up]: key_string += 'Up'
		elif key in [Key.page_down, Key.down]: key_string += 'Down'
		elif key == Key.left: key_string += 'Left'
		elif key == Key.right: key_string += 'Right'
		elif key == Key.esc: key_string += 'Escape'
		elif key == Key.tab: key_string += 'Tab'
		elif key == Key.caps_lock: key_string += 'CapsLock'
		elif key == Key.space: key_string += 'Space'
		elif key == Key.backspace: key_string += 'Backspace'
		elif key == Key.enter: key_string += 'Enter'
		elif key == Key.insert: key_string += 'Insert'
		elif key == Key.delete: key_string += 'Delete'
		elif key == Key.media_play_pause: key_string += 'MediaPlayPause'
		elif key == Key.media_previous: key_string += 'MediaPrevious'
		elif key == Key.media_next: key_string += 'MediaNext'
		elif key == Key.media_volume_up: key_string += 'MediaVolumeUp'
		elif key == Key.media_volume_up: key_string += 'MediaVolumeDown'

	return key_string.removesuffix('+')


def key_press(key):
	global modifier_shift
	global modifier_ctrl
	global modifier_alt
	global modifier_meta
	if key == Key.shift:
		modifier_shift = True
	if key == Key.ctrl:
		modifier_ctrl = True
	if key == Key.alt:
		modifier_alt = True
	if key == Key.cmd:
		modifier_meta = True

	response = {
		'action': 'press',
		'key': get_key_string(key),
	}
	input_log.append(response)


def key_release(key):
	global modifier_shift
	global modifier_ctrl
	global modifier_alt
	global modifier_meta

	response = {
		'action': 'release',
		'key': get_key_string(key),
	}
	input_log.append(response)

	if key == Key.shift:
		modifier_shift = False
	if key == Key.ctrl:
		modifier_ctrl = False
	if key == Key.alt:
		modifier_alt = False
	if key == Key.cmd:
		modifier_meta = False



listener:Listener = Listener(on_press=key_press, on_release=key_release)
listener.start()


def quit():
	listener.stop()

