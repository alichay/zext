foreign_system_library dl   "dl";
foreign_system_library libc "c";

foreign dl {
	// NOTE(zachary): Despite the _NS prefix, this is a pure C function.
	NSGetExecutablePath :: proc(buf: ^u8, bufsize: ^u32) #link_name "_NSGetExecutablePath" ---;
}