cd addons/PyBundle/Interpreter/
nuitka "interpreter.py" --onefile --lto=yes
rm -rf interpreter.dist
rm -rf interpreter.build
rm -rf interpreter.onefile-build
