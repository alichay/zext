import posix "posix_types.odin";
import "../../feature_test.odin";

S_IFMT   : posix.mode : 0o0170000;
S_IFBLK  : posix.mode : 0o0060000;
S_IFCHR  : posix.mode : 0o0020000;
S_IFIFO  : posix.mode : 0o0010000;
S_IFREG  : posix.mode : 0o0100000;
S_IFDIR  : posix.mode : 0o0040000;
S_IFLNK  : posix.mode : 0o0120000;
S_IFSOCK : posix.mode : 0o0140000;



S_IRUSR : posix.mode : 0o0400;
S_IWUSR : posix.mode : 0o0200;
S_IXUSR : posix.mode : 0o0100;
S_IRWXU : posix.mode : S_IRUSR | S_IWUSR | S_IXUSR;

S_IRGRP : posix.mode : S_IRUSR >> 3;
S_IWGRP : posix.mode : S_IWUSR >> 3;
S_IXGRP : posix.mode : S_IXUSR >> 3;
S_IRWXG : posix.mode : S_IRWXU >> 3;

S_IROTH : posix.mode : S_IRGRP >> 3;
S_IWOTH : posix.mode : S_IWGRP >> 3;
S_IXOTH : posix.mode : S_IXGRP >> 3;
S_IRWXO : posix.mode : S_IRWXG >> 3;

S_ISUID : posix.mode : 0o04000;
S_ISGID : posix.mode : 0o02000;
S_ISVTX : posix.mode : 0o01000;


when feature_test.LINUX_WIN && ODIN_ARCH == "amd64" {
	Stat :: struct #ordered {
		device_id:     posix.dev, // ID of device containing file
		inode:         posix.ino, // File serial number
		nlink:         posix.nlink, // Number of hard links
		mode:          posix.mode, // Mode of the file
		uid:           posix.uid, // User ID of the file's owner
		gid:           posix.gid, // Group ID of the file's group
		_padding:      i32, // 32 bits of padding
		rdev:          posix.dev, // Device ID, if device
		size:          posix.off, // Size of the file, in bytes
		block_size:    posix.blksize, // Optimal blocksize for I/O
		blocks:        posix.blkcnt, // Number of 512-byte blocks allocated

		last_access:   posix.Time_Spec, // Time of last access
		modified:      posix.Time_Spec, // Time of last modification
		status_change: posix.Time_Spec, // Time of last status change

		_reserve1,
		_reserve2,
		_reserve3:     i64
	}
} else when feature_test.LINUX_WIN && ODIN_ARCH == "x86" {
	Stat :: struct #ordered {
		device_id:     posix.dev, // ID of device containing file
		_pad1:         u16, // 16 bits of padding
		_inode:        posix.ino, // File serial number, maybe?
		mode:          posix.mode, // Mode of the file
		nlink:         posix.nlink, // Number of hard links
		uid:           posix.uid, // User ID of the file's owner
		gid:           posix.gid, // Group ID of the file's group
		rdev:          posix.dev, // Device ID, if device
		_pad2:         u16, // 16 bytes of padding
		size:          posix.off, // Size of the file, in bytes
		block_size:    posix.blksize, // Optimal blocksize for I/O
		blocks:        posix.blkcnt, // Number of 512-byte blocks allocated

		last_access:   posix.Time_Spec, // Time of last access
		modified:      posix.Time_Spec, // Time of last modification
		status_change: posix.Time_Spec, // Time of last status change

		inode:         posix.ino, // File serial number

		_reserve1,
		_reserve2:     i64
	}
} else when feature_test.LINUX_WIN && ODIN_ARCH == "arm" {
	Stat :: struct #ordered {
		device_id:     posix.dev, // ID of device containing file
		_pad1:         u16, // 16 bits of padding
		_inode:        posix.ino, // File serial number, maybe?
		mode:          posix.mode, // Mode of the file
		nlink:         posix.nlink, // Number of hard links
		uid:           posix.uid, // User ID of the file's owner
		gid:           posix.gid, // Group ID of the file's group
		rdev:          posix.dev, // Device ID, if device
		_pad2:         u16, // 16 bytes of padding
		size:          posix.off64, // Size of the file, in bytes
		block_size:    posix.blksize, // Optimal blocksize for I/O
		blocks:        posix.blkcnt64, // Number of 512-byte blocks allocated

		last_access:   posix.Time_Spec, // Time of last access
		modified:      posix.Time_Spec, // Time of last modification
		status_change: posix.Time_Spec, // Time of last status change

		inode:         posix.ino64, // File serial number
	}
} else when feature_test.LINUX_WIN && ODIN_ARCH == "arm64" {
	Stat :: struct #ordered {
		device_id:     posix.dev, // ID of device containing file
		inode:         posix.ino64, // File serial number
		mode:          posix.mode, // Mode of the file
		nlink:         posix.nlink, // Number of hard links
		uid:           posix.uid, // User ID of the file's owner
		gid:           posix.gid, // Group ID of the file's group
		rdev:          posix.dev, // Device ID, if device
		_pad1:         u64, // 64 bits of padding
		size:          posix.off64, // Size of the file, in bytes
		block_size:    posix.blksize, // Optimal blocksize for I/O
		_pad2:         i32, // 32 bits of padding
		blocks:        posix.blkcnt64, // Number of 512-byte blocks allocated

		last_access:   posix.Time_Spec, // Time of last access
		modified:      posix.Time_Spec, // Time of last modification
		status_change: posix.Time_Spec, // Time of last status change

		_reserve1,
		_reserve2:     i32,
	}
} else when ODIN_OS == "osx" || ODIN_OS == "ios" {
	// Apple has gone completely 64bit, so we don't need to worry about x86 compat.
	// Apparently they use the same struct on x64 and on ARM. Glad to see someone's sane.

	Stat :: struct #ordered {
		device_id:     posix.dev, // ID of device containing file
		mode:          posix.mode, // Mode of the file
		nlink:         posix.nlink, // Number of hard links
		inode:         posix.ino, // File serial number
		uid:           posix.uid, // User ID of the file's owner
		gid:           posix.gid, // Group ID of the file's group
		rdev:          posix.dev, // Device ID, if device
		last_access:   posix.Time_Spec, // Time of last access
		modified:      posix.Time_Spec, // Time of last modification
		status_change: posix.Time_Spec, // Time of last status change
		birthtime:     posix.Time_Spec, // Time of file creation
		size:          posix.off, // Size of the file, in bytes
		blocks:        posix.blkcnt, // Number of 512-byte blocks allocated
		block_size:    posix.blksize, // Optimal blocksize for I/O
		flags:         u32, // User-defined flags for the file
		gen:           u32, // File generation number ...?

		_reserve1:      i32, // 32 bits of padding
		_reserve2,
		_reserve3:     i64,
	}
} else when ODIN_OS == "bsd" {
	// TODO(zachary): Implement!
	_ :: compile_assert(false); // Unsupported architecture
} else {
	_ :: compile_assert(false); // Unsupported architecture
}

_is_type :: inline proc(mode: posix.mode, mask: posix.mode) -> bool do return (mode & S_IFMT) == mask;

S_ISBLK  :: inline proc(mode: posix.mode) -> bool do return _is_type(mode, S_IFBLK);
S_ISCHR  :: inline proc(mode: posix.mode) -> bool do return _is_type(mode, S_IFCHR);
S_ISDIR  :: inline proc(mode: posix.mode) -> bool do return _is_type(mode, S_IFDIR);
S_ISFIFO :: inline proc(mode: posix.mode) -> bool do return _is_type(mode, S_IFIFO);
S_ISREG  :: inline proc(mode: posix.mode) -> bool do return _is_type(mode, S_IFREG);
S_ISLNK  :: inline proc(mode: posix.mode) -> bool do return _is_type(mode, S_IFLNK);
S_ISSOCK :: inline proc(mode: posix.mode) -> bool do return _is_type(mode, S_IFSOCK);