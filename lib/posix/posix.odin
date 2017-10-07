import "core:os.odin";
import "../feature_test.odin";
import "../str.odin";

when ODIN_OS != "windows" {
	// TODO: Perhaps emulate POSIX calls on Windows?
	export "posix_stat.odin";
	export "posix_types.odin";

	foreign_system_library libc "c";
	foreign libc {
		unix_getcwd :: proc(buf: ^u8, size: i64) -> ^u8        #link_name "getcwd" ---;
		unix_closedir :: proc(handle: ^DIR) -> i32             #link_name "closedir" ---;
		unix_chdir :: proc(path: ^u8) -> i32                   #link_name "chdir" ---;
		//unix_open  :: proc(^u8, int, mode) -> os.Handle        #link_name "open" ---;
		unix_mkdir :: proc(path: ^u8, perms: mode) -> i32      #link_name "mkdir" ---;
		unix_readlink :: proc(path, out_buf: ^u8, buf_size: feature_test.size_t) -> feature_test.ssize_t #link_name "readlink" ---;
		unix_realpath :: proc(in_buf, out_buf: ^u8) -> ^u8     #link_name "realpath" ---;
	}
	
	// A gross hack because the function signature in os_linux.odin and os_x.odin are wrong.
	unix_open :: proc(path: ^u8, access_mode: int, perms: mode) -> os.Handle #inline {
		return (cast(proc(^u8, int, #c_vararg ...mode) -> os.Handle #cc_c)os._unix_open)(path, access_mode, perms);
	}

	when ODIN_OS == "linux" {
		foreign libc {
			unix_readdir :: proc(^DIR) -> ^dirent #cc_c           #link_name "readdir64" ---;
			unix_fstat   :: proc(fd: i32, stat: ^Stat) -> int     #link_name "fstat64"   ---;
			unix_lstat   :: proc(path: ^u8, stat: ^Stat) -> int   #link_name "lstat64"   ---;
			unix_stat    :: proc(path: ^u8, stat: ^Stat) -> int   #link_name "stat64"    ---;
		}
	} else when ODIN_OS == "osx" {
		foreign libc {
			unix_readdir :: proc(^DIR) -> ^dirent #cc_c          #link_name "readdir$INODE64" ---;
			unix_fstat   :: proc(fd: i32, stat: ^Stat) -> int    #link_name "fstat$INODE64"   ---;
			unix_lstat   :: proc(path: ^u8, stat: ^Stat) -> int  #link_name "lstat$INODE64"   ---;
			unix_stat    :: proc(path: ^u8, stat: ^Stat) -> int  #link_name "stat$INODE64"    ---;
		}
	} else {
		foreign libc {
			unix_readdir :: proc(^DIR) -> ^dirent #cc_c           #link_name "readdir" ---;
			unix_fstat   :: proc(fd: i32, stat: ^Stat) -> int     #link_name "fstat"   ---;
			unix_lstat   :: proc(path: ^u8, stat: ^Stat) -> int   #link_name "lstat"   ---;
		}
		unix_stat :: proc(path: ^u8, stat: ^Stat) -> int #inline do return cast(int)os._unix_stat(path, stat);
	}
	when ODIN_OS == "osx" {
		foreign libc {
			// NOTE(zachary): For backwards compat with 32-bit binaries,
			//   Apple has an $INODE64 postfix on the `stat` family of functions.
			unix_opendir :: proc(path: ^u8) -> ^DIR                   #link_name "opendir$INODE64" ---;
		}
	} else {
		foreign libc {
			// NOTE(zachary): IOS/WatchOS/TVOS don't have this backwards-compatability.
			unix_opendir :: proc(path: ^u8) -> ^DIR                   #link_name "opendir" ---;
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

	fstat :: proc(fd: i32) -> (Stat, int) #inline {
		s: Stat;
		ret_int := unix_fstat(fd, &s);
		return s, int(ret_int);
	}
	lstat :: proc(path: string) -> (Stat, int) #inline {
		s: Stat;
		cstr := str.new_c_string(path);
		defer free(cstr);
		ret_int := unix_lstat(cstr, &s);
		return s, int(ret_int);
	}
	stat :: proc(path: string) -> (Stat, int) #inline {
		s: Stat;
		cstr := str.new_c_string(path);
		defer free(cstr);
		ret_int := unix_stat(cstr, &s);
		return s, int(ret_int);
	}
}