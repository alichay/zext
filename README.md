# ZEXT
### A series of public-domain standard library extensions for Odin.

It is reccomended to use the `./lib` directory as a collection. For example, in `test.sh`, I add the compile flag `-collection=zext=lib`.

 + `json.odin` - A fully featured JSON reader and writer.
 + `fs.odin` - A simple filesystem library. This will be expanded over time. Windows support is meh, but PRs are welcome!
 + `gl.odin` - An OpenGL extension loader based on [Vassvik's work](https://github.com/vassvik/odin-gl). Loads OpenGL functions dynamically for any platform with `load_up_to`. NOTE: Function names differ from the standard due to personal taste.
 + `child.odin` - A *very* unfinished child process library. At some point, this will be expanded so that the library is easier to use, but for now it's in a half-broken state.
 + `os.odin` - A small set of extensions over Odin's `core:os.odin`. This is a drop-in replacement, as it `export`s the standard `os.odin`
 + `str.odin` - A string library that acts as an expansion of `core:strings.odin`. This is a drop-in replacement, as it `export`s `core:strings.odin`
 + `feature_test.odin` - A small set of constants that make creating future-proof `when` statements easy. For example, test for an OS's vendor (`MICROSOFT`) rather than the name (`WINDOWS`)
 + `sys/posix/posix.odin` - Some miscellaneous POSIX function definitions. Mostly, this exists for `child.odin` and `fs.odin`
 + `sys/apple/core_foundation.odin` - A couple functions and types from CoreFoundation on macOS. This exists solely for loading the OpenGL framework in `gl.odin`