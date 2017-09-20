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
		_unix_getcwd :: proc(buf: ^u8, size: i64) -> ^u8 #cc_c #link_name "getcwd" ---;
		_unix_closedir :: proc(^_DIR) -> i32             #cc_c #link_name "closedir" ---;
		_unix_chdir :: proc(^u8) -> i32                  #cc_c #link_name "chdir" ---;
	}
	when ODIN_OS == "linux" {
		foreign libc {
			_unix_readdir :: proc(^_DIR) -> ^_dirent #cc_c #link_name "readdir64" ---;
		}
	} else when ODIN_OS == "osx" {
		foreign libc {
			_unix_readdir :: proc(^_DIR) -> ^_dirent #cc_c #link_name "readdir$INODE64" ---;
		}
	} else {
		foreign libc {
			_unix_readdir :: proc(^_DIR) -> ^_dirent #cc_c #link_name "readdir" ---;
		}
	}
	when ODIN_OS == "osx" {
		foreign libc {
			_unix_opendir :: proc(path: ^u8) -> ^_DIR #cc_c #link_name "opendir$INODE64" ---;
		}
	} else {
		foreign libc {
			_unix_opendir :: proc(path: ^u8) -> ^_DIR #cc_c #link_name "opendir" ---;
		}
	}

	_Dirent_Type :: enum u8 {
		DT_UNKNOWN  = 0,
		DT_FIFO     = 1,
		DT_CHR      = 2,
		DT_DIR      = 4,
		DT_BLK      = 6,
		DT_REG      = 8,
		DT_LNK      = 10,
		DT_SOCK     = 12,
		DT_WHT      = 14
	}

	when ODIN_OS == "linux" {
		_dirent :: struct #ordered {
			inode: os.ino;
			off: os.off;
			reclen: u16;
			kind: _Dirent_Type;
			name: [256]u8;
		}
	} else {
		_dirent :: struct #ordered {
			inode: os.ino;
			seekoff: u64;
			reclen: u16;
			namlen: u16;
			kind: _Dirent_Type;
			name: [256]u8;
		}
	}

	_DIR :: rawptr;

}

chdir :: proc(path: string) -> bool {

	c_path := strings.new_c_string(path);
	defer(free(c_path));

	when ODIN_OS == "windows" {

		_ := compile_assert(false);
		return false;

	} else {

		return _unix_chdir(c_path) == 0;
	}
}

// Allocates memory...?
// At least, the array is allocated. Not sure about the contents.
list_dir :: proc(path: string) -> ([]string, bool) {

	c_path := strings.new_c_string(path);
	defer(free(c_path));

	when ODIN_OS == "windows" {

		_ := compile_assert(false);
		return nil, false;
		
	} else {

		dp := _unix_opendir(c_path);

		if dp == nil do return nil, false;

		defer((cast(proc(^_DIR))_unix_closedir)(dp));

		paths : [dynamic]string;

		ep := _unix_readdir(dp);

		for ;ep != nil; ep = _unix_readdir(dp) {
			child := strings.to_odin_string(&ep.name[0]);
			if child != "." && child != ".." do	append(&paths, child);
		}

		return paths[..], true;
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
		info, ok := os.stat(path);
		when ODIN_OS == "osx" {if !ok do return false;}
		else {if ok != 0 do return false;}
		return os.S_ISREG(info.mode);
	}
}

is_directory :: proc(path: string) -> bool #inline {

	when ODIN_OS == "windows" {

		info := win32.get_file_attributes_a(path);
		return (info != win32.INVALID_FILE_ATTRIBUTES && 
		       (info &  win32.FILE_ATTRIBUTE_DIRECTORY));

	} else {

		info, ok := os.stat(path);
		when ODIN_OS == "osx" {if !ok do return false;}
		else {if ok != 0 do return false;}
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
		info, ok := os.stat(path);
		when ODIN_OS == "osx" {if !ok do return false;}
		else {if ok != 0 do return false;}
		return !(os.S_ISREG(info.mode) || os.S_ISDIR(info.mode));
	}
}

// Returns the current working directory.
// Allocates memory.
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

is_path_separator :: proc(c: u8) -> bool #inline {
	when ODIN_OS == "windows" {
		return c == '\\' || c == '/';
	} else {
		return c == '/';
	}
}

// Return the filename of a path. E.g. /tmp/my/file.odin -> file.odin
base_name :: proc(path: string) -> string {
	first_non_sep := -1;
	for i := len(path)-1; i>0; i-=1 {
		if is_path_separator(path[i]) {
			if first_non_sep != -1 do return path[i+1..first_non_sep+1];
		} else if first_non_sep == -1 do first_non_sep = i;
	}
	return path;
}
// Return the parent of a path. E.g. /tmp/my/file.odin -> file.odin, /tmp/my -> /tmp, /tmp/my///// -> /tmp
parent_name :: proc(path: string) -> string {
	hit_non_sep := false;
	for i := len(path)-1; i>0; i-=1 {
		if is_path_separator(path[i]) {
			if hit_non_sep do return path[0..i];
		} else do hit_non_sep = true;
	}
	return path;
}