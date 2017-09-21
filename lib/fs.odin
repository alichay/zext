import "core:os.odin";
import "str.odin";
import "posix.odin";
import "feature_test.odin";

when ODIN_OS == "windows" {
	import win32 "core:sys/windows.odin";
	foreign_system_library "kernel32.lib";
	foreign kernel32 {
		_get_current_directory :: proc(buf_len: u32, buf: ^u8) #link_name "GetCurrentDirectoryA" ---;
		_create_directory :: proc(^u8, rawptr) -> i32          #link_name "CreateDirectoryA" ---;        
	}
} else {
	foreign_system_library libc "c";
	foreign libc {
		_unix_getcwd :: proc(buf: ^u8, size: i64) -> ^u8        #link_name "getcwd" ---;
		_unix_closedir :: proc(^_DIR) -> i32                    #link_name "closedir" ---;
		_unix_chdir :: proc(^u8) -> i32                         #link_name "chdir" ---;
		//_unix_open  :: proc(^u8, int, posix.mode) -> os.Handle  #link_name "open" ---;
		_unix_mkdir :: proc(^u8, posix.mode) -> i32             #link_name "mkdir" ---;
	}
	
	// A gross hack because the function signature in os_linux.odin and os_x.odin are wrong.
	_unix_open :: proc(path: ^u8, mode: int, perms: posix.mode) -> os.Handle #inline {
		when feature_test.APPLE {
			return (cast(proc(^u8, int, #c_vararg ...posix.mode) -> os.Handle #cc_c)os.unix_open)(path, mode, perms);
		} else {
			return (cast(proc(^u8, int, #c_vararg ...posix.mode) -> os.Handle #cc_c)os._unix_open)(path, mode, perms);
		}
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
			// NOTE(zachary): For backwards compat with 32-bit binaries,
			//   Apple has an $INODE64 postfix on the `stat` family of functions.
			_unix_stat    :: proc(path: ^u8, stat: ^posix.Stat) -> int  #link_name "stat$INODE64" ---;
			_unix_opendir :: proc(path: ^u8) -> ^_DIR                   #link_name "opendir$INODE64" ---;
		}
	} else {
		foreign libc {
			// NOTE(zachary): IOS/WatchOS/TVOS don't have this backwards-compatability.
			_unix_opendir :: proc(path: ^u8) -> ^_DIR                   #link_name "opendir" ---;
		}
		_unix_stat :: proc(path: ^u8, stat: ^posix.Stat) -> int #inline {
			when feature_test.APPLE {
				return cast(int)os.unix_stat(path, cast(^os.Stat)stat);
			} else {
				return cast(int)os._unix_stat(path, cast(^os.Stat)stat);
			}
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
			inode: posix.ino;
			off: posix.off;
			reclen: u16;
			kind: _Dirent_Type;
			name: [256]u8;
		}
	} else {
		_dirent :: struct #ordered {
			inode: posix.ino;
			seekoff: u64;
			reclen: u16;
			namlen: u16;
			kind: _Dirent_Type;
			name: [256]u8;
		}
	}

	_DIR :: rawptr;

	stat :: proc(path: string) -> (posix.Stat, int) #inline {
		s: posix.Stat;
		cstr := str.new_c_string(path);
		defer free(cstr);
		ret_int := _unix_stat(cstr, &s);
		return s, int(ret_int);
	}

}

_DEFAULT_PERMS :: posix.S_IRUSR | posix.S_IWUSR | posix.S_IRGRP | posix.S_IWGRP | posix.S_IROTH | posix.S_IWOTH;

// Get a handle to the file pointed to by the path.
open :: proc(path: string, flags := os.O_WRONLY | os.O_TRUNC, perms: posix.mode = _DEFAULT_PERMS) -> (os.Handle, bool) #inline {
	when ODIN_OS == "windows" {
		h, ok := os.open(path, flags, perms);
		return h, (ok == os.ERROR_NONE);
	} else {
		cstr := str.new_c_string(path);
		defer free(cstr);
		handle := _unix_open(cstr, flags, perms);
		return handle, (handle >= 0);
	}
}

// A wrapper around os.close so that they can be called from fs
close :: proc(fd: os.Handle) #inline {
	os.close(fd);
}

// A wrapper around os.read so that they can be called from fs
read :: proc(fd: os.Handle, data: []u8) -> (int, bool) #inline {
	rv, err := os.read(fd, data);
	return rv, err == 0;
}

// A wrapper around os.write so that they can be called from fs
write :: proc(fd: os.Handle, data: string) -> (int, bool) #inline {
	rv, err := os.write(fd, cast([]u8)data);
	return rv, err == 0;
}

// A wrapper around os.write so that they can be called from fs
write :: proc(fd: os.Handle, data: []u8) -> (int, bool) #inline {
	rv, err := os.write(fd, data);
	return rv, err == 0;
}

// A wrapper around os.seek so that they can be called from fs
seek :: proc(fd: os.Handle, offset: i64, whence: int) -> (i64, bool) #inline {
	rv, err := os.seek(fd, offset, whence);
	return rv, err == 0;
}

// A wrapper around os.file_size so that they can be called from fs
file_size :: proc(fd: os.Handle) -> (i64, bool) #inline {
	rv, err := os.file_size(fd);
	return rv, err == 0;
}

mkdir :: proc(path: string, perms: posix.mode = _DEFAULT_PERMS) {
	parent := parent_name(path);
	if !exists(parent) do mkdir(parent, perms);
	when ODIN_OS == "windows" {
		_create_directory(c_path, nil);
	} else {
		c_path := str.new_c_string(path);
		defer(free(c_path));
		_unix_mkdir(c_path, perms);
	}
}

chdir :: proc(path: string) -> bool {

	c_path := str.new_c_string(path);
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

	c_path := str.new_c_string(path);
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
			child := str.to_odin_string(&ep.name[0]);
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
		info, ok := stat(path);
		when ODIN_OS == "osx" {if !ok do return false;}
		else {if ok != 0 do return false;}
		return posix.S_ISREG(info.mode);
	}
}

is_directory :: proc(path: string) -> bool #inline {

	when ODIN_OS == "windows" {

		info := win32.get_file_attributes_a(path);
		return (info != win32.INVALID_FILE_ATTRIBUTES && 
		       (info &  win32.FILE_ATTRIBUTE_DIRECTORY));

	} else {

		info, ok := stat(path);
		when ODIN_OS == "osx" {if !ok do return false;}
		else {if ok != 0 do return false;}
		return posix.S_ISDIR(info.mode);
	}
}
is_dir :: proc(path: string) -> bool #inline do return is_directory(path);

// Not a directory, file, or s-link.
// Always false on win32.
is_special :: proc(path: string) -> bool #inline {

	when ODIN_OS == "windows" {
		return false;
	} else {
		info, ok := stat(path);
		when ODIN_OS == "osx" {if !ok do return false;}
		else {if ok != 0 do return false;}
		return !(posix.S_ISREG(info.mode) || posix.S_ISDIR(info.mode));
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
				return str.to_odin_string(&buf[0]), true;
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
		odin_str := str.to_odin_string(heap_cwd);

		return str.new_string(odin_str), true;
	}
}

when ODIN_OS == "windows" {
	SEPERATOR :: '\\';
} else {
	SEPERATOR :: '/';
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

// Convert a relative path to an absolute path
to_absolute_from_cwd :: proc(paths: ...string) -> (string, bool) {
	cwd_str, ok := cwd();
	if !ok do return "", false;
	defer free(cwd_str);
	spread := make([]string, len(paths)+1);
	spread[0] = cwd_str;
	for _, i in paths do spread[i+1] = paths[i];
	return to_absolute(...spread), true;
}

import "core:fmt.odin";
to_absolute :: proc(paths: ...string) -> string {
	assert(len(paths) > 0);
	if len(paths) > 1 {
		second := paths[1];
		when ODIN_OS == "windows" {
			if len(second) > 2 do
				if (second[0] >= 'a' && second[0] <= 'z') || (second[0] >= 'A' && second[0] <= 'Z') {
					if second[1] == ':' do return to_absolute(...paths[1..]);
				}
		} else {
			if len(paths[0]) > 1 do
				if(second[0] == '/') do return to_absolute(...paths[1..]);
		}
	}
	path_ctor: [dynamic]string;
	defer free(path_ctor);
	last_entry: int = 0;
	str_len := 0;
	for path in paths {
		start_char := 0;
		for i in 0..len(path)+1 {
			c := (i == len(path)) ? 0 : path[i];
			if is_path_separator(c) || i == len(path) {
				str := path[start_char..i];
				if str == "." {}
				else if str == ".." {
					if last_entry != 0 {
						last_entry -= 1;
						str_len -= len(path_ctor[last_entry]);
					}
				} else if last_entry != 0 && str == "" {
				} else if last_entry == len(path_ctor) {
					last_entry = append(&path_ctor, str);
					str_len += len(str);
				} else {
					path_ctor[last_entry] = str;
					last_entry += 1;
					str_len += len(str);
				}
				start_char = i+1;
			}
		}
	}
	str_len += len(path_ctor) - 1;
	final_str := make([]u8, str_len>1?str_len:1);
	gi := 0;
	for p, i in path_ctor[..last_entry] {
		if i != 0 || last_entry == 1 {
			final_str[gi] = '/';
			gi += 1;
		}
		for j in 0..len(p) {
			final_str[gi+j] = p[j];
		}
		gi += len(p);
	}
	return string(final_str);
}