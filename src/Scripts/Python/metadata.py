import json
from tinytag import TinyTag

valid_extensions = [
	'mp3',
	'ogg',
	'wav',
	'flac',
]


# Safely get an item in an array.
def list_get (l, idx, default=None):
	try:
		return l[idx]
	except IndexError:
		return default


# Get audio metadata.
def get_audio_meta(tag, path):
	raw_meta:dict = tag.as_dict()
	meta:dict = {}

	# Add list properties.
	for property in ['artist', 'musicbrainz_artistid', 'album', 'albumartist', 'title', 'year', 'comment', 'copyright']:
		meta[property] = list_get(raw_meta.get(property,[]),0,'')
	# Add number properties.
	for property in ['duration', 'channels', 'bitrate', 'bitdepth', 'samplerate', 'track', 'disc', 'filesize']:
		meta[property] = raw_meta.get(property,0)

	# Replay gain.
	meta['replaygain_album'] = 0.0
	meta['replaygain_track'] = 0.0
	try: meta['replaygain_album'] = float(raw_meta.get('replaygain_album_gain','')[0].split(' ')[0])
	except: pass
	try: meta['replaygain_track'] = float(raw_meta.get('replaygain_track_gain','')[0].split(' ')[0])
	except: pass

	# Album artist.
	if meta['albumartist'] == '':
		meta['albumartist'] = meta['artist']

	# Album year.
	meta['year'] = meta['year'].split('-')[0]

	# Get genres.
	meta['genres'] = raw_meta.get('genre',[])
	if len(meta['genres']) == 1:
		meta['genres'] = meta['genres'][0] \
			.replace(' ; ','&&') \
			.replace('; ','&&') \
			.replace(';','&&') \
			.replace(' , ','&&') \
			.replace(', ','&&') \
			.replace(',','&&')
		meta['genres'] = meta['genres'].split('&&')

	# Get synced & unsynced lyrics.
	meta['synced_lyrics'] = ''
	meta['unsynced_lyrics'] = ''
	all_lyric_fields = [
		list_get(raw_meta.get('lyrics',[]),0,''),
		list_get(raw_meta.get('unsyncedlyrics',[]),0,''),
		list_get(raw_meta.get('lyrics',[]),1,''),
		list_get(raw_meta.get('syncedlyrics',[]),0,''),
	]
	for lyric_field in all_lyric_fields:
		if lyric_field == '': continue
		if lyric_field.__contains__('[') and lyric_field.__contains__(':'):
			meta['synced_lyrics'] = lyric_field
		else:
			meta['unsynced_lyrics'] = lyric_field

	# If only found synced lyrics, fill in unsynced lyrics.
	if meta['synced_lyrics'] != '' and meta['unsynced_lyrics'] == '':
		meta['unsynced_lyrics'] = ''.replace('[','***').replace(']','***').split('***')

	# Get image.
	cover_image = tag.images.any
	meta['image_extension'] = ''
	if cover_image is not None:
		image_extension = str(cover_image.mime_type.replace('image/',''))
		meta['image_extension'] = image_extension
	meta['path'] = path

	return meta


def meta_as_file_name(meta, mode=0):
	## Track mode.
	if mode == 0:
		return '%s__%s__%s-%s' % (meta['artist'].replace('/','_'), meta['album'].replace('/','_'), meta['title'].replace('/','_'), str(int(meta['duration'])))
	# Album mode.
	if mode == 1:
		return '%s__%s' % (meta['albumartist'].replace('/','_'), meta['album'].replace('/','_'))


def save_audio_meta(tag, meta, output_path):
	formatted_meta = json.dumps(meta)
	file = open(output_path, 'w')
	file.write(formatted_meta)
	file.close()


def save_audio_cover(tag, output_path):
	cover_image = tag.images.any
	if cover_image is not None:
		file = open(output_path, 'wb')
		file.write(cover_image.data)
		file.close()


# MAIN LOOP
# ---------


while True:
	raw_input = input()
	args = raw_input.split(' [&&] ')
	cmd = list_get(args, 0, '')
	input_paths = []
	image_output_dir = ''
	for arg in args:
		if arg.startswith('(img_out) '):
			image_output_dir = arg.removeprefix('(img_out) ')
		if arg.startswith('(audio) '):
			input_paths.append(arg.removeprefix('(audio) '))


	if cmd == 'get_audio_meta':
		if len(input_paths) == 0: continue
		entries = []
		for input_path in input_paths:
			tag:TinyTag = TinyTag.get(input_path, image=True)
			meta = get_audio_meta(tag, input_path)

			if image_output_dir != '':
				cover_path = image_output_dir+'/'+meta_as_file_name(meta, 1)+'.'+meta['image_extension']
				if meta['image_extension'] != '':
					meta['cover_path'] = cover_path
					save_audio_cover(tag, cover_path)

			entries.append(meta)

		print(json.dumps(entries))
