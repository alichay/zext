foreign import dl   "system:dl";
foreign import libc "system:c";

foreign dl {
	// NOTE(zachary): Despite the _NS prefix, this is a pure C function.
	NSGetExecutablePath :: proc(buf: ^u8, bufsize: ^u32) #link_name "_NSGetExecutablePath" ---;
}