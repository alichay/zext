import "os.odin";
import "str.odin";
using import "feature_test.odin";

when ODIN_OS == "windows" {
	import win32 "core:sys/windows.odin";
	foreign import "system:kernel32.lib";
	@(default_calling_convention = "std")
	foreign kernel32 {
		@(link_name = "GetCurrentDirectoryA") _get_current_directory :: proc(buf_len: u32, buf: ^u8) ---;
		@(link_name = "CreateDirectoryA")     _create_directory      :: proc(^u8, rawptr) -> i32     ---;

		// What on earth was I trying to do here?
		// get_module_filename :: proc() -> i32           #cc_std #link_name "GetLastError"  ---;

	}
} else {
	import "sys/posix/posix.odin";
}

_DEFAULT_PERMS :: posix.S_IRUSR | posix.S_IWUSR | posix.S_IRGRP | posix.S_IWGRP | posix.S_IROTH | posix.S_IWOTH;

// Get a handle to the file pointed to by the path.
open :: inline proc(path: string, flags := os.O_WRONLY | os.O_TRUNC, perms: posix.mode = _DEFAULT_PERMS) -> (os.Handle, bool) {
	when ODIN_OS == "windows" {
		h, ok := os.open(path, flags, perms);
		return h, (ok == os.ERROR_NONE);
	} else {
		cstr := str.new_c_string(path);
		defer free(cstr);
		handle := posix.open(cstr, flags, perms);
		return handle, (handle >= 0);
	}
}

// A wrapper around os.close so that they can be called from fs
close :: inline proc(fd: os.Handle) {
	os.close(fd);
}

// A wrapper around os.read so that they can be called from fs
read :: inline proc(fd: os.Handle, data: []u8) -> (int, bool) {
	rv, err := os.read(fd, data);
	return rv, err == 0;
}

// A wrapper around os.write so that they can be called from fs
write :: inline proc(fd: os.Handle, data: string) -> (int, bool) {
	rv, err := os.write(fd, cast([]u8)data);
	return rv, err == 0;
}

// A wrapper around os.write so that they can be called from fs
write :: inline proc(fd: os.Handle, data: []u8) -> (int, bool) {
	rv, err := os.write(fd, data);
	return rv, err == 0;
}

// A wrapper around os.seek so that they can be called from fs
seek :: inline proc(fd: os.Handle, offset: i64, whence: int) -> (i64, bool) {
	rv, err := os.seek(fd, offset, whence);
	return rv, err == 0;
}

// A wrapper around os.file_size so that they can be called from fs
file_size :: inline proc(fd: os.Handle) -> (i64, bool) {
	rv, err := os.file_size(fd);
	return rv, err == 0;
}

read_entire_file :: inline proc(path: string) -> (data: []u8, success: bool) {
	return os.read_entire_file(path);
}

read_file_to_string :: inline proc(path: string) -> (data: string, success: bool) {
	buffer, success := os.read_entire_file(path);
	if(!success) {
		return "", false;
	}
	return string(buffer), true;
}


mkdir :: proc(path: string, perms: posix.mode = _DEFAULT_PERMS) {
	parent := parent_name(path);
	if !exists(parent) do mkdir(parent, perms);
	when ODIN_OS == "windows" {
		_create_directory(c_path, nil);
	} else {
		c_path := str.new_c_string(path);
		defer(free(c_path));
		posix.mkdir(c_path, perms);
	}
}

chdir :: proc(path: string) -> bool {

	c_path := str.new_c_string(path);
	defer(free(c_path));

	when ODIN_OS == "windows" {

		_ := compile_assert(false);
		return false;

	} else {

		return posix.chdir(c_path) == 0;
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

		dp := posix.opendir(c_path);

		if dp == nil do return nil, false;

		defer((cast(proc(^posix.DIR))posix.closedir)(dp));

		paths : [dynamic]string;

		ep := posix.readdir(dp);

		for ;ep != nil; ep = posix.readdir(dp) {
			child := str.to_odin_string(&ep.name[0]);
			if child != "." && child != ".." do	append(&paths, child);
		}

		return paths[..], true;
	}
}

// Returns whether or not a file exists.
// NOTE: Avoid patters similar to `if exists(path) do open(file)` because this is prone to race conditions.
exists :: inline proc(path: string) -> bool {

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

is_file :: inline proc(path: string) -> bool {

	when ODIN_OS == "windows" {

		return !is_directory(path);

	} else {
		info, err := posix.stat(path);
		if err != 0 do return false;
		return posix.S_ISREG(info.mode);
	}
}

is_directory :: inline proc(path: string) -> bool {

	when ODIN_OS == "windows" {

		info := win32.get_file_attributes_a(path);
		return (info != win32.INVALID_FILE_ATTRIBUTES && 
		       (info &  win32.FILE_ATTRIBUTE_DIRECTORY));

	} else {

		info, err := posix.stat(path);
		if err != 0 do return false;
		return posix.S_ISDIR(info.mode);
	}
}
is_dir :: inline proc(path: string) -> bool do return is_directory(path);

// Not a directory, file, or s-link.
// Always false on win32.
is_special :: inline proc(path: string) -> bool {

	when ODIN_OS == "windows" {
		return false;
	} else {
		info, err := posix.stat(path);
		if err != 0 do return false;
		return !(posix.S_ISREG(info.mode) || posix.S_ISDIR(info.mode));
	}
}

// Allocates memory.
read_link :: proc(path: string) -> (string, bool) {

	when feature_test.MICROSOFT {

		// Dupes the string so that you can free the return value safely.
		return str.dup(path);

	} else {

		if link_info, err := posix.lstat(path); err == 0 {

			buf := make([]u8, link_info.size);
			err = cast(type_of(err))posix.readlink(&path[0], &buf[0], cast(feature_test.size_t)link_info.size);
			if err == 0 do return string(buf), true;
			free(buf);
		}

		return "", false;
	}
}

// Returns the directory the current program's binary file is in.
// Allocates memory.
get_binary_path :: proc() -> (string, bool) {

	when APPLE {
		

	fmt.println("A");
		size : u32;

	fmt.println("B");
		os.NSGetExecutablePath(nil, &size);

	fmt.println("C");
		if size == 0 do return "", false;

	fmt.println("D", size);
		buf := make([]u8, size);

	fmt.println("E");
		defer free(buf);

	fmt.println("F");
		os.NSGetExecutablePath(&buf[0], &size);

	fmt.println("G");

		abs_path := posix.realpath(&buf[0], nil);

	fmt.println("H");
		defer os.heap_free(abs_path);


	fmt.println("I");
		return str.dup(str.to_odin_string(abs_path)), true;

	} else when LINUX {
		return read_link("/proc/self/exe");
	} else when MICROSOFT {
		_ := compile_assert(false, "TODO");
	} else when BSD {
		_ := compile_assert(false, "TODO");
	} else {
		_ := compile_assert(false, "Unsupported OS");
	}
	return "", false;
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
		heap_cwd := posix.getcwd(nil, 0);
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
is_path_separator :: inline proc(c: u8) -> bool {
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