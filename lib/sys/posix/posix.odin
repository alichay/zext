import "core:os.odin";
import "../../feature_test.odin";
import "../../str.odin";

when ODIN_OS != "windows" {
	// TODO: Perhaps emulate POSIX calls on Windows?
	export "posix_stat.odin";
	export "posix_types.odin";

	foreign import libc "system:c";
	foreign libc {
		@(link_name = "getcwd")    getcwd   :: proc(buf: ^u8, size: i64) -> ^u8         ---;
		@(link_name = "closedir")  closedir :: proc(handle: ^DIR) -> i32                ---;
		@(link_name = "chdir")     chdir    :: proc(path: ^u8) -> i32                   ---;
		@(link_name = "open")      _open    :: proc(path: ^u8, mode: int) -> os.Handle  ---;
		@(link_name = "mkdir")     mkdir    :: proc(path: ^u8, perms: mode) -> i32      ---;
		@(link_name = "readlink")  readlink :: proc(path, out_buf: ^u8, buf_size: feature_test.size_t) -> feature_test.ssize_t ---;
		@(link_name = "realpath")  realpath :: proc(in_buf, out_buf: ^u8) -> ^u8        ---;
	}
	
	// A gross hack because the function signature in os_linux.odin and os_x.odin are wrong.
	open :: inline proc(path: ^u8, access_mode: int, perms: mode) -> os.Handle {
		return (cast(proc"c"(^u8, int, #c_vararg ...mode) -> os.Handle)_open)(path, access_mode, perms);
	}

	when ODIN_OS == "linux" {
		foreign libc {
			@(link_name = "readdir64")        readdir  :: proc(^DIR) -> ^dirent               ---;
			@(link_name = "fstat64")          _fstat   :: proc(fd: i32, stat: ^Stat) -> int   ---;
			@(link_name = "lstat64")          _lstat   :: proc(path: ^u8, stat: ^Stat) -> int ---;
			@(link_name = "stat64")           _stat    :: proc(path: ^u8, stat: ^Stat) -> int ---;
		}
	} else when ODIN_OS == "osx" {
		foreign libc {
			@(link_name = "readdir$INODE64")  readdir  :: proc(^DIR) -> ^dirent               ---;
			@(link_name = "fstat$INODE64")    _fstat   :: proc(fd: i32, stat: ^Stat) -> int   ---;
			@(link_name = "lstat$INODE64")    _lstat   :: proc(path: ^u8, stat: ^Stat) -> int ---;
			@(link_name = "stat$INODE64")     _stat    :: proc(path: ^u8, stat: ^Stat) -> int ---;
		}
	} else {
		foreign libc {
			@(link_name = "readdir")          readdir  :: proc(^DIR) -> ^dirent               ---;
			@(link_name = "fstat")            _fstat   :: proc(fd: i32, stat: ^Stat) -> int   ---;
			@(link_name = "lstat")            _lstat   :: proc(path: ^u8, stat: ^Stat) -> int ---;
		}
		_stat :: inline proc(path: ^u8, stat: ^Stat) -> int do return cast(int)os._unix_stat(path, stat);
	}
	when ODIN_OS == "osx" {
		foreign libc {
			// NOTE(zachary): For backwards compat with 32-bit binaries,
			//   Apple has an $INODE64 postfix on the `stat` family of functions.
			@(link_name = "opendir$INODE64")  opendir  :: proc(path: ^u8) -> ^DIR ---;
		}
	} else {
		foreign libc {
			// NOTE(zachary): IOS/WatchOS/TVOS don't have this backwards-compatability.
			@(link_name = "opendir")          opendir  :: proc(path: ^u8) -> ^DIR ---;
		}
	}

	Dirent_Type :: enum u8 {
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
		dirent :: struct #ordered {
			inode: ino,
			off: off,
			reclen: u16,
			kind: Dirent_Type,
			name: [256]u8,
		}
	} else {
		dirent :: struct #ordered {
			inode: ino,
			seekoff: u64,
			reclen: u16,
			namlen: u16,
			kind: Dirent_Type,
			name: [256]u8,
		}
	}

	DIR :: rawptr;

	fstat :: inline proc(fd: i32) -> (Stat, int) {
		s: Stat;
		ret_int := _fstat(fd, &s);
		return s, int(ret_int);
	}
	lstat :: inline proc(path: string) -> (Stat, int) {
		s: Stat;
		cstr := str.new_c_string(path);
		defer free(cstr);
		ret_int := _lstat(cstr, &s);
		return s, int(ret_int);
	}
	stat :: inline proc(path: string) -> (Stat, int) {
		s: Stat;
		cstr := str.new_c_string(path);
		defer free(cstr);
		ret_int := _stat(cstr, &s);
		return s, int(ret_int);
	}
}