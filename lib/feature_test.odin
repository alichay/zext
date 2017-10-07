
IS_64     :: ODIN_ARCH == "amd64" || ODIN_ARCH == "arm64";
IS_32     :: !IS_64;
IS_INTEL  :: ODIN_ARCH == "amd64" || ODIN_ARCH == "x86";
IS_ARM    :: ODIN_ARCH == "arm"   || ODIN_ARCH == "arm64";
MICROSOFT :: ODIN_OS == "windows";
LINUX     :: ODIN_OS == "linux";
// Adding Windows to act as a basic posix compatability layer.
LINUX_WIN :: ODIN_OS == "linux" || ODIN_OS == "windows";
APPLE     :: ODIN_OS == "osx" || ODIN_OS == "ios" || ODIN_OS == "watchos" || ODIN_OS == "tvos";
BSD       :: false; // TODO(zachary): What if we're compiling on BSD? (although Odin does not support this target yet)

when IS_64 {
	size_t :: u64;
	ssize_t :: i64;
} else {
	size_t :: u32;
	ssize_t :: i32;
}