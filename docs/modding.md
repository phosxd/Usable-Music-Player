This page focusses on **creating** & **installing** PCK mods for use in the app.

# Create your first mod
It is recommended to read the [Godot PCK Documentation](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_pcks.html) before continuing. This will tell you how PCKs work & how to export your project as a PCK file.
## Prerequisites
- Specialized Godot editor build ([Godot UMP](https://github.com/phosxd/godot-for-ump)) which you may need to compile for your platform. This will be used to actually create your mod & export it as a PCK file.

## Project structure
PCKs can dynamically replace or add files to the project, it is important to adhere to UMP's file structure so things do not change or break unexpectedly.

Make sure to thouroughly inspect the source code file structure so you know where things should go. The root directory of your mod is the same as this repository's `src/` directory.

## Mod script
Mod scripts allow you to run code during the initialization of your PCK mod.

Create a new GDScript file with a **unique name** inside of the `Mod Scripts` folder. You can use the [example script](https://github.com/phosxd/Usable-Music-Player/tree/main/src/Mod Scripts/example_mod.gd) as a template.
The `init` function of the script is called when the PCK mod is loaded.

## Implement addons
You can throw addons into the `addons` folder in your PCK. You will need to enable it in code, this can be done in your mod script.

## Custom theme
To add a custom theme, simply create a new directory in the `Themes` folder & put a custom `theme.tres` file inside it.
You can also override scenes for a custom layout & UI, refer to the [default theme](https://github.com/phosxd/Usable-Music-Player/tree/main/src/Themes/Normal) for the file structure you should follow in your custom theme folder.
