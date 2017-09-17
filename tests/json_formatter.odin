import "core:fmt.odin";
import "core:os.odin";
import "core:raw.odin";
import "zext:json.odin";


main :: proc() {
	
	json_file, success := os.read_entire_file("tests/test.json");
	data, err := json.parse(string(json_file));

	if err.code == json.Error_Code.NO_ERROR {

		fmt.println(json.write(data));
		json.free_value(data);
	} else {
		fmt.println("Failed to parse json.", err);
	}
}