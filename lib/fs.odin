import "core:os.odin";
import "core:strings.odin";

when ODIN_OS == "windows" {
	import win32 "core:sys/windows.odin";
	foreign_system_library "kernel32.lib";
	foreign kernel32 {
		_get_current_directory :: proc(buf_len: u32, buf: ^u8) #cc_std #link_name "GetCurrentDirectoryA" ---;
	}
} else {
	foreign_system_library libc "c";
	foreign libc {
		_unix_getcwd :: proc(buf: ^u8, size: i64) -> ^u8 #link_name "getcwd" ---;
	}

}

// Returns whether or not a file exists.
// NOTE: Avoid patters similar to `if exists(path) do open(file)` because this is prone to race conditions.
exists :: proc(path: string) -> bool #inline {

	when ODIN_OS == "windows" {

		h, err := os.open(path);

		if err == os.ERROR_NONE {
			os.close(h);
			return true;
		}
		return false;
	} else {
		return os.access(path, os.R_OK);
	}
}

is_file :: proc(path: string) -> bool #inline {

	when ODIN_OS == "windows" {

		return !is_directory(path);

	} else {
		info, err := os.stat(path);
		if err do return false;
		return os.S_ISREG(info.mode);
	}
}
import "core:fmt.odin";
is_directory :: proc(path: string) -> bool #inline {

	when ODIN_OS == "windows" {

		info := win32.get_file_attributes_a(path);
		return (info != win32.INVALID_FILE_ATTRIBUTES && 
		       (info &  win32.FILE_ATTRIBUTE_DIRECTORY));

	} else {

		info, err := os.stat(path);
		fmt.println(info, err);
		if err do return false;
		return os.S_ISDIR(info.mode);
	}
}
is_dir :: proc(path: string) -> bool #inline do return is_directory(path);

// Not a directory, file, or s-link.
// Always false on win32.
is_special :: proc(path: string) -> bool #inline {

	when ODIN_OS == "windows" {
		return false;
	} else {
		info, err := os.stat(path);
		if err do return false;
		return !(os.S_ISREG(info.mode) || os.S_ISDIR(info.mode));
	}
}

cwd :: proc() -> (string, bool) {

	when ODIN_OS == "windows" {

		/* GetCurrentDirectory's return value:
			1. function succeeds: the number of characters that are written to
				the buffer, not including the terminating null character.
			2. function fails: zero
			3. the buffer (lpBuffer) is not large enough: the required size of
				the buffer, in characters, including the null-terminating character.
		*/

		// Good enough...?
		//buf: [4096]u8;
		len := _get_current_directory(0, nil);

		if len != 0 {

			buf := make([]u8, len);
			written := _get_current_directory(len, &buf[0]);

			if written != 0 {
				return strings.to_odin_string(&buf[0]), true;
			}

		}

		return nil, false;


	} else {

		// This is non-compliant to the POSIX spec, but both Linux and BSD/macOS implement this.
		// NOTE: Apparently Solaris does not, but I don't think that's really a target anyone uses anymore.
		heap_cwd := _unix_getcwd(nil, 0);
		// We want to free this result instead of returning it so that all return values are allocated
		// with the proper allocator.
		defer(os.heap_free(heap_cwd));
		// A temporary converted string that will be duplicated with data from the context's allocator.
		odin_str := strings.to_odin_string(heap_cwd);

		return strings.new_string(odin_str), true;
	}
}