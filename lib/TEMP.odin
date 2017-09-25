// Because the compiler is initially going to be built in Odin,
// but it will soon be self-hosting, this is a file that provides bridges
// from Odin types to the types that I will provide

size_t :: u64;
ssize_t :: i64;

when ODIN_OS == "osx" {
	OS_FAMILY :: "apple";
} else when ODIN_OS == "linux" {
	OS_FAMILY :: "linux";
} else when ODIN_OS == "windows" {
	OS_FAMILY :: "microsoft";
}