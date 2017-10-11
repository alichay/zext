using import "core:c.odin";
import "../../feature_test.odin";

when feature_test.LINUX_WIN && feature_test.IS_INTEL {
	blkcnt :: c_long;
	ino :: c_ulong;
	off :: c_long;
	blksize :: c_long;
	dev :: u64;
	gid :: u32;
	mode :: u32;
	nlink :: c_ulong;
	pid :: i32;
	ssize :: c_long;
	time :: c_long;
	uid :: u32;
} else when feature_test.LINUX_WIN && feature_test.IS_ARM {
	dev :: u64;
	ino :: c_ulong;
	ino64 :: u64;
	mode :: u32;
	nlink :: u32;
	uid :: u32;
	gid :: u32;
	off :: c_long;
	off64 :: i64;
	blksize :: i32;
	blkcnt :: c_long;
	ssize :: c_long;
	time :: c_long;
	blkcnt64 :: i64;
} else when feature_test.APPLE {
	blkcnt :: i64;
	blksize :: i32;
	dev :: i32;
	gid :: u32;
	ino :: u64;
	mode :: u16;
	nlink :: u16;
	off :: i64;
	pid :: i32;
	ssize :: c_long;
	time :: c_long;
	uid :: u32;
} // TODO(zachary): BSD
else {
	_ :: compile_assert(false); // Unsupported os/architecture
}


when feature_test.IS_64 {
	Nanosecond :: i64;
	Time_Spec :: struct #ordered {
		seconds:     i64,
		nanoseconds: Nanosecond,
	}
} else {
	Nanosecond :: i32;
	Time_Spec :: struct #ordered {
		seconds:     i32,
		nanoseconds: Nanosecond,
		_reserved:   i32,
	}
}