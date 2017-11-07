when ODIN_OS == "freebsd" {
	export "freebsd.odin";
} else when ODIN_OS == "netbsd" {
	export "netbsd.odin";
} else {
	_ := compile_assert(false);
}

using import "../../feature_test.odin"

foreign import libc "system:c";

foreign libc {

	@(link_name = "sysctl") sysctl :: proc(name: ^i32, namelen: u32, oldp: rawptr, oldplen: ^size_t, newp: rawptr, newlen: size_t) -> i32 ---;
}