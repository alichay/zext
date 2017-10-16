when ODIN_OS == "freebsd" {
	export "freebsd.odin";
} else when ODIN_OS == "netbsd" {
	export "netbsd.odin";
} else {
	_ := compile_assert(false, "Unsupported BSD-like system.");
}

foreign import libc "system:c";

foreign libc {

	sysctl :: proc(name: ^i32, namelen: u32, oldp: rawptr, oldplen: ^size_t,
	               newp: rawptr, newlen: size_t) -> i32 #link_name "sysctl" ---;
}