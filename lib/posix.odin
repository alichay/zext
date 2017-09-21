when ODIN_OS != "windows" {
	// TODO: Perhaps emulate POSIX calls on Windows?
	export "zext:posix/posix_stat.odin";
	export "zext:posix/posix_types.odin";
}