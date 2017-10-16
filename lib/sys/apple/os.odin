when ODIN_OS == "osx" {
	export "macos.odin";
} else {
	_ := compile_assert(false, "Unsupported Apple OS.");
}

foreign import libc "system:c";