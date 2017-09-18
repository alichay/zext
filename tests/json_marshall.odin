import "zext:json.odin";
import "core:os.odin";
import "core:fmt.odin";

Sub_Type :: struct {
	tester: string;
}

My_Type :: struct {
	s: string;
	fl32: f32;
	fl64: f64;
	integer: int;
	uinteger: uint;
	int32: i32;
	int64: i64;
	boolean: bool;
	sub: Sub_Type;
	dynamic_arr: [dynamic]int;
	fixed_arr: [5]int;
	arr: []int;
}

import "core:strings.odin";
marshall_ptr :: proc(result: rawptr, ti: ^Type_Info, val: ^json.Value) -> json.Error {
	
	ti := type_info_base_without_enum(ti);

	match info in ti {
		case Type_Info.Integer:

			if(val.kind != json.Value_Type.INT) {
				return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
			}

			match ti.size {
				case 1:  (cast(^i8)   result)^ = cast(i8)   val.integer;
				case 2:  (cast(^i16)  result)^ = cast(i16)  val.integer;
				case 4:  (cast(^i32)  result)^ = cast(i32)  val.integer;
				case 8:  (cast(^i64)  result)^ = cast(i64)  val.integer;
				case 16: (cast(^i128) result)^ = cast(i128) val.integer;
				case:    return json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
			}
			return json.Error{json.Error_Code.NO_ERROR, 0, 0};
			
		case Type_Info.Pointer:
			return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};

		case Type_Info.Any:
			// Is there really anything I can do here???
			return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};

		case Type_Info.String:

			if(val.kind != json.Value_Type.STRING) {
				return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
			}

			(cast(^string)result)^ = strings.new_string(val.str);

			return json.Error{json.Error_Code.NO_ERROR, 0, 0};

		case Type_Info.Float:

			if(val.kind == json.Value_Type.F64) {
				match ti.size {
					case 4: (cast(^f32) result)^ = cast(f32) val.float;
					case 8: (cast(^f64) result)^ = cast(f64) val.float;
					case:   return json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
				}
			} else if(val.kind == json.Value_Type.INT) {
				match ti.size {
					case 4: (cast(^f32) result)^ = cast(f32) val.integer;
					case 8: (cast(^f64) result)^ = cast(f64) val.integer;
					case:   return json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
				}
			} else {
				return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
			}

		case Type_Info.Boolean:
			
			if val.kind == json.Value_Type.BOOL {
				
				(cast(^bool)result)^ = val.boolean;

			} else if val.kind == json.Value_Type.INT {

				if val.integer == 0 {

					(cast(^bool)result)^ = false;

				} else if val.integer == 1 {

					(cast(^bool)result)^ = true;

				} else {

					return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
				}
			}

		case Type_Info.Array: // Fixed

			if val.kind != json.Value_Type.ARRAY {
				return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
			}

			if info.count >= len(val.arr) {
				for e, i in val.arr do marshall_ptr(cast(^u8)result + info.elem_size * i, info.elem, val.arr[i]);
			} else {
				return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
			}

		case Type_Info.Vector:

			if val.kind == json.Value_Type.ARRAY {

				if info.count >= len(val.arr) {

					for e, i in val.arr do marshall_ptr(cast(^u8)result + info.elem_size * i, info.elem, val.arr[i]);
					return json.NO_ERROR;

				}


			} else if val.kind == json.Value_Type.OBJECT {

				match info.count {

					case 2:
						x := val.object
				}
			}

			return T{}, json.Error{json.Error_Code.INCOMPATIBLE_TYPES, val.x, val.y};
	}
}
marshall :: proc(T: type, val: ^json.Value) -> (T, json.Error) {
	result: T;
	err := marshall_ptr(&result, type_info_of(T), val);
	return result, err;
}

print_type :: proc(T: ^Type_Info) {
	ti := type_info_base_without_enum(T);
	match id in ti.variant {
		case Type_Info.Array: fmt.println("array");
		case Type_Info.Dynamic_Array: fmt.println("dynamic array");
		case Type_Info.Slice: fmt.println("slice");
		case: fmt.println("Unaccounted for:", T);
	}
}

main :: proc() {
	x : My_Type;
	print_type(type_info_of(x.fixed_arr));
	print_type(type_info_of(x.dynamic_arr));
	print_type(type_info_of(x.arr));
	val, err := json.parse(`{
		"s": "teststr",
		"fl32": 0.42,
		"fl64": 0.3213214,
		"integer": -152,
		"uinteger": 10,
		"int32": 43242,
		"int64": 34213421312,
		"boolean": true,
		"sub": {
			"tester": "Hello, world!"
		},
		"arr": [10, 423, 6453, 10]`);

	//my_item := marshall(My_Type, val);
	//fmt.println(my_item);
}