# Simple Command Line Interface for handling everything that Godot cannot.
#
# # # get_audio_meta:
#
# Gets the input audio file metadata using TinyTag.
# Outputs "out.txt" & "out.jpg" in the given output directory.
#
# SCHEMA: <input_path> <output_path>
#
#
# # # dump_audio_meta:
#
# Returns an array of audio meta items.
# Dumps all album cover images into the given directory.
#
# SCHEMA: <input_dir_path> <image_output_dir>


import os
import sys
import json
from tinytag import TinyTag

valid_extensions = [
	'mp3',
	'ogg',
	'wav',
	'flac',
]


# Safely get an item in an array.
def list_get (l, idx, default):
	try:
		return l[idx]
	except IndexError:
		return default


# Get audio metadata.
def get_audio_meta(tag, path):
	raw_meta:dict = tag.as_dict()
	meta:dict = {}

	# Add list properties.
	for property in ['artist', 'album', 'albumartist', 'title', 'genre', 'year', 'comment', 'lyrics', 'copyright']:
		meta[property] = list_get(raw_meta.get(property,[]),0,'')
	# Add number properties.
	for property in ['duration', 'channels', 'bitrate', 'bitdepth', 'samplerate', 'track', 'disc']:
		meta[property] = raw_meta.get(property,0)

	if meta['albumartist'] == '':
		meta['albumartist'] = meta['artist']

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



if sys.argv[1] == 'get_audio_meta':
	input_path = sys.argv[2]
	output_path = sys.argv[3]
	tag:TinyTag = TinyTag.get(input_path, image=True)
	meta = get_audio_meta(tag, input_path)

	cover_path = output_path+'/out.%s' % meta['image_extension']
	save_audio_cover(tag, meta, cover_path)
	meta['cover_path'] = cover_path
	save_audio_meta(tag, meta, output_path+'/out.txt')


if sys.argv[1] == 'dump_audio_meta':
	dump = []
	for subdir, dirs, files in os.walk(sys.argv[2]):
		for file in files:
			path = os.path.join(subdir, file)
			# Check file type.
			file_ext = path.split('.')[-1].lower()
			if file_ext not in valid_extensions:
				continue
			# Add to dump & save image.
			tag:TinyTag = TinyTag.get(path, image=True)
			meta = get_audio_meta(tag, path)
			meta['cover_path'] = ''
			if meta['image_extension'] != '':
				cover_path = sys.argv[3]+'/'+meta_as_file_name(meta, 1)+'.'+meta['image_extension']
				meta['cover_path'] = cover_path
			save_audio_cover(tag, cover_path)
			dump.append(meta)

	json = json.dumps(dump)
	print(json)
