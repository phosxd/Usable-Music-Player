Python files should be compiled as standalone binaries using PyInstaller or Nuitka (preferabley).
This directory should include a `Build.sh` file that will automatically build the present binaries using Nuitka.

# When using Nuitka:
Make sure Nuitka is installed with **all** of it's dependencies. You also need to install `python3-devel` for the `Python.h` header files.

# Post compilation:
After generating the binaries, move them to `BIN/`.
The file name should follow this format: `<name>.<linux | windows>.<x86_64 | x86_32 | arm64 | arm32>`
