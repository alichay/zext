import "feature_test.odin";
export "core:os.odin";

when      feature_test.APPLE     { export "apple/os.odin"     }
else when feature_test.LINUX     { export "linux/os.odin"     }
else when feature_test.BSD       { export "bsd/os.odin"       }
else when feature_test.MICROSOFT { export "microsoft/os.odin" }
else {
	_ := compile_assert(false, "Unsupported platform!");
}