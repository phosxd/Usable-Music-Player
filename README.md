Introducing the Linux-first music player made with [Godot](https://godotengine.org)!

# Features

## Media controls
- Play/pause
- Previous/next. Skipping to previous while more than a few seconds into the song will bring you to the beginning of the song instead.
- Volume 0-100%.
- Volume mute button.
- Shuffle queue.
- Repeat track or queue.

## MPRIS D-Bus integration
- Track metadata for track title, album title, artist title, & album art.
- Track progress & length.
- Track lyrics (via `extra:lyrics` & `extra:lyricsSynced` metadata fields).

**Controls:**
- Play/pause
- Previous/next
- Seek track progress.
- Set volume 0-100%

## Audio formats
Godot does not natively support many audio formats, so we are quite limited unfortunately.
The formats currently supported by Godot are WAV, OggVorbis, & MP3. However we can also play 2-channel FLaC using a community-made Godot extension.
