// Temporarily setting this
using import "TEMP.odin";
export "core:os.odin";

when OS_FAMILY == "apple" {
	export "apple/os.odin";
} else when OS_FAMILY == "linux" {
	export "linux/os.odin";
} else when OS_FAMILY == "bsd" {
	export "bsd/os.odin";
} else when OS_FAMILY == "microsoft" {
	export "microsoft/os.odin";
}