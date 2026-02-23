# Simple Command Line Interface for handling everything that Godot cannot.
#
# get_audio_meta:
#
# Gets the input audio file metadata using TinyTag.
# Outputs "out.txt" & "out.jpg" in the given output directory.


import sys
import json
from tinytag import TinyTag


def list_get (l, idx, default):
	try:
		return l[idx]
	except IndexError:
		return default



# Get audio metadata.
if sys.argv[1] == 'get_audio_meta':
	input_path = sys.argv[2]
	output_path = sys.argv[3]
	tag:TinyTag = TinyTag.get(input_path, image=True)

	raw_meta:dict = tag.as_dict()
	meta:dict = {}
	# Add list properties.
	for property in ['artist', 'album', 'title', 'genre', 'year', 'comment']:
		meta[property] = list_get(raw_meta.get(property,[]),0,'')
	# Add number properties.
	for property in ['channels', 'bitrate', 'bitdepth', 'samplerate', 'track']:
		meta[property] = raw_meta.get(property,0)

	# Save text metadata.
	formatted_meta = json.dumps(meta)
	file = open(output_path+'/out.txt', 'w')
	file.write(formatted_meta)
	file.close()

	# Save image metadata.
	cover_image = tag.images.front_cover
	if cover_image is not None:
		file = open(output_path+'/out.jpg', 'wb')
		file.write(cover_image.data)
		file.close()
