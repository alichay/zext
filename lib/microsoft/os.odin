// TODO(zachary): Are there more OS types to worry about?
//                Probably not.

when ODIN_OS == "windows" {
	export "win32.odin";
} else {
	_ := compile_assert(false, "Unsupported BSD-like system.");
}