Python files should be compiled as standalone binaries using PyInstaller.
Command: `pyinstaller --onefile "path/to/python_script"`

After generating the binaries, move them to `PROJECT/CLIs/<platform>` with `<platform>` being the platform you compiled the binary for.
Make sure to remove any left over files generated in this directory.
