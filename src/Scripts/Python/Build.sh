#pyinstaller --onefile "Main.py"
nuitka "Main.py" --onefile --lto=yes
