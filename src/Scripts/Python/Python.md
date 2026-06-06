Python files should be compiled as standalone binaries using PyInstaller or Nuitka (preferabley).
This directory should include a `Build.sh` file that will automatically build the Python executable using Nuitka.

# When using Nuitka:
Make sure Nuitka is installed with **all** of it's dependencies. You also need to install `python3-devel` for the `Python.h` header files.

# Post compilation:
After generating the executable, move it to `BIN/`.
The file name should follow this format: `interface.<linux | windows>.<x86_64 | x86_32 | arm64 | arm32>`
