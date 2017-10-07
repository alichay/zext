import "zext:fs.odin";
import "core:fmt.odin";

main :: proc() {

	assert(fs.base_name("/home/some_user/gungnir/test.odin") == "test.odin");
	assert(fs.base_name("/home/some_user/gungnir///") == "gungnir");
	assert(fs.base_name("/home/some_user/Programming/gungnir/a") == "a");
	assert(fs.parent_name("/home/some_user/gungnir/test.odin") == "/home/some_user/gungnir");
	assert(fs.parent_name("/home/some_user/gungnir///") == "/home/some_user");
	assert(fs.parent_name("/home/some_user/Programming/gungnir/a") == "/home/some_user/Programming/gungnir");
	
	fmt.println("test passed");
}