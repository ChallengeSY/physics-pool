## Installing
Usually, a package comes with binaries pre-compiled for Windows. Thus, all you have to do is extract the package that Physics Pool and its assets were in, and you are all set. Physics Pool has been tested on Windows XP through 11. It has been compiled using FreeBASIC 1.10.1.

To build new Windows binaries isn't *that* difficult, but you'll need to install additional libraries to ensure proper linking. Afterwards, just type in `fbc PPool.bas PPool.rc -s gui` in a command shell, or use an IDE able to pass that command.

### Common Libraries
Regardless of platform, you will likely need to install additional libraries, notably runtime and/or development variants of SDL and SDL_mixer.

### GNU/Linux
Installing under GNU/Linux, on the other hand, is not so simple. Since the architecture for this system is all over the place, no binaries are provided for GNU/Linux. A simple makefile is supplied.

### FreeBSD
We presume instructions are similiar to GNU/Linux, but this is untested. Feel free to experiment as need be, until you are able to build your own program.

### macOS
There never was an official build of the compiler for this OS. Good luck getting it to work with an unofficial build.

### Wine
Alternatively, if you can figure out how to use [Wine](http://www.winehq.org/), then you can use it to run the pre-compiled Windows binaries. This is likely the only way to run Nebunoid outside of the systems above, as FreeBASIC compiler tools are not provided for any other platforms (except DOS).

That being said, it *might* be remotely possible to compile a native DOS build, but this is extremely tricky to pull off, and is impossible to cross-compile from a 64-bit Windows system. Building for DOS is untested.
