Introducing the Linux-first music player made with [Godot](https://godotengine.org)!

# Features

## Audio formats
Godot does not natively support many audio formats, so we are quite limited unfortunately.
The formats currently supported by Godot are WAV, OggVorbis, & MP3. However we can also play 2-channel FLaC using a community-made Godot extension.

**UMP supports:**
- MP3
- OggVorbis
- WAV
- FLaC (2-channel only)

There are no plans to support any more formats since most libraries are either MP3 or FLaC anyway & it would take a tremendous amount of time to implement ALaC, multi-cahnnel FLaC, or other formats in the current Godot ecosystem.

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


## Multiple libraries & auto-scanning
You can add, manage, & scan multiple libraries all indenpendantly. UMP will never edit or delete your music, so editing a library has no effect on your files or file structure.

You may also setup automatic scanning, which will run checkups on all your libraries at the set interval. This is not something you want to do if your library doesn't change often, because your libraries are already rescanned on application startup.

Libraries mounted over LAN will show up with a network icon instead of a folder icon.

## File structrue independant
Your library can be organized however you want, all that matters is that your music is tagged with the correct album & artist titles.
However, UMP still benefits from organized libraries as it allows for grabbing images & lyrics from outside the audio metadata as well.

## ReplayGain
If your music has ReplayGain metadata, UMP can use that to normalize volume during playback. You have the choice to use only track values, only whole album value, or "auto" which will always use album values, or track values if they aren't available.

You may also apply a pre-amp to adjust it's volume when active.

## Automatically fetch track lyrics & artist images
Artist images & track lyrics are automatically grabbed from free public APIs.
If results are innacurate or unreliable you can always disable the APIs or replace lyrics/images with your own.
