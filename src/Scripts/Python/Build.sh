#pyinstaller --onefile "metadata.py"
nuitka "metadata.py" --onefile --lto=yes
