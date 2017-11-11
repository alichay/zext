import "feature_test.odin";

when      feature_test.APPLE     { export "sys/apple/os.odin"     }
else when feature_test.LINUX     { export "sys/linux/os.odin"     }
else when feature_test.BSD       { export "sys/bsd/os.odin"       }
else when feature_test.MICROSOFT { export "sys/microsoft/os.odin" }
else {
	_ := compile_assert(false, "Unsupported platform!");
}