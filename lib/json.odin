import "core:strings.odin";
import "core:raw.odin";
import "core:fmt.odin";
import "core:os.odin";
import "core:strconv.odin";
import "core:utf8.odin";
import "core:utf16.odin";

Null :: u8;

Value_Type :: enum {
	NOT_SET,
	STRING,
	OBJECT,
	ARRAY,
	F64,
	INT,
	BOOL,
	NULL
}
Value :: struct {
	using data: struct #raw_union {
		str: string;
		object: map[string]^Value;
		arr: [dynamic]^Value;
		float: f64;
		integer: int;
		boolean: bool;
	};
	keystore: [dynamic]string;
	kind: Value_Type;
}

Error_Code :: enum u8 {
	NO_ERROR, UNEXPECTED_END, INVALID_CHAR, INVALID_ESCAPE
}
Error :: struct {
	code: Error_Code;
	x, y: int;
}
NO_ERROR := Error{Error_Code.NO_ERROR, 0, 0};

// PUBLIC API
// Use these functions to interface with this JSON api.

// Serialize a JSON value into a string recursively.
write :: proc(json: ^Value) -> string {
	dynstr: [dynamic]u8;
	write_value(json, 0, &dynstr);
	return to_string(dynstr);
}

// Parse a JSON file. Returns a Value struct, which represents the root object node.
parse :: proc(file: string) -> (^Value, Error) {

	parser: Parser;
	parser.pos = 0;
	parser.file = file;
	parser.x = 0;
	parser.y = 1;
	return parse_value(&parser);
}

// Use this to free the JSON data when you're done with it.
free_value :: proc(val: ^Value, caller := #caller_location) {

	// For debugging parsing issues:
	//   fmt.println("Json failed to parse. Error at", caller);

	if val.kind == Value_Type.STRING {
		free(val.str);

	} else if val.kind == Value_Type.ARRAY {


		if val.arr != nil && (cast(^raw.Dynamic_Array)&val.arr).data != nil {
			for p in val.arr do free_value(p);
			free(val.arr);
		}


	} else if val.kind == Value_Type.OBJECT {

		if val.object != nil {
			for key in val.keystore {
				item, ok := val.object[key];
				if ok do free(item);
				free(key);
			}
			free(val.keystore);
			free(val.object);
		}
	}


	free(cast(rawptr)val);
}

// END PUBLIC API


to_string :: proc(char: rune) -> string #inline {
	return transmute(string) raw.String {
		data = cast(^u8) &char,
		len  = size_of(char),
	};
}

to_string :: proc(dyn: [dynamic]u8) -> string #inline do return (cast(^string) &dyn)^;
to_string :: proc(slc: []u8)        -> string #inline do return (cast(^string) &slc)^;

is_digit :: proc(char: rune) -> bool #inline do return char >= '0' && char <= '9';

is_digit :: proc(char: u8) -> bool #inline do return is_digit(cast(rune)char);

is_whitespace :: proc(char: rune) -> bool #inline do return char == ' ' || char == '\t' || char == '\r' || char == '\n';

is_whitespace :: proc(char: u8) -> bool #inline do return is_whitespace(cast(rune)char);

append_rune :: proc(buf: ^[dynamic]u8, r: rune) #inline {
	bytes, size := utf8.encode_rune(r);
	for i in 0..size do append(buf, bytes[i]);
}

append_escaped_string :: proc(buf: ^[dynamic]u8, str: string) {

	escape := false;

	for char in str {
		if escape {
			c: rune;

			match char {
			// @todo: support escaped newline
			case 'n': c = '\n';
			case 'r': c = '\r';
			case 't': c = '\t';
			case:     c = char; 
			}

			append_rune(buf, c);
			escape = false;
		} else {
			match char {
			// @todo: err if quotes not on ends of string
			case '\\': escape = true;
			case '"':  continue;
			case:      append_rune(buf, char);
			}
		}
	}
}

indent :: proc(buf: ^[dynamic]u8, ind: int) #inline {
	for i in 0..ind do append(buf, '\t');
}

write_value :: proc(val: ^Value, ind: int, buf: ^[dynamic]u8) {
	match val.kind {
		case Value_Type.STRING: {
			append(buf, '"');
			append_escaped_string(buf, val.str);
			append(buf, '"');
		}
		case Value_Type.OBJECT: {
			append(buf, '{');
			append(buf, '\n');
			for key, i in val.keystore {
				indent(buf, ind+1);
				append(buf, '"');
				append_escaped_string(buf, key);
				append(buf, "\" : ");
				write_value(val.object[key], ind+1, buf);
				if i < len(val.keystore) - 1 do append(buf, ',');
				append(buf, '\n');
			}
			indent(buf, ind);
			append(buf, '}');
		}
		case Value_Type.ARRAY: {
			append(buf, '[');
			append(buf, '\n');
			for newval, i in val.arr {
				indent(buf, ind+1);
				write_value(newval, ind+1, buf);
				if i < len(val.arr) - 1 do append(buf, ',');
				append(buf, '\n');
			}
			indent(buf, ind);
			append(buf, ']');
		}
		case Value_Type.F64: {

			tmpbuf: [386]u8;

			str := strconv.append_float(tmpbuf[1..1], val.float, 'f', 6, 64);
			str = string(tmpbuf[1..len(str)]);
			if str[0] == '+' do str = str[1..len(str)];
			append(buf, str);
		}
		case Value_Type.INT: {

			tmpbuf: [386]u8;

			str := strconv.itoa(tmpbuf[1..1], val.integer);
			str = string(tmpbuf[...len(str)]);
			append(buf, str);
			
		}
		case Value_Type.BOOL: {
			if val.boolean do append(buf, "true"); else do append(buf, "false");
		}
		case Value_Type.NULL: {
			append(buf, "null");
		}
	}
}

Parser :: struct {
	file: string;
	pos, x, y: int;
}

skip_whitespace :: proc(using parser: ^Parser) -> Error {

	for ; pos<len(file); pos+=1 {

		x += 1;

		c := file[pos];

		if c == '\n' {
			x = 0;
			y += 1;
			continue;
		}

		if is_whitespace(c) do continue;
		
		break;
	}

	if pos == len(file)-1 && is_whitespace(file[pos]) do return Error{Error_Code.UNEXPECTED_END, x, y};
	return NO_ERROR;
}

parse_object :: proc(using parser: ^Parser) -> (^Value, Error) {
	
	// We start at the {, so let's go ahead and move up.
	x += 1;
	pos += 1;

	val := new(Value);
	val.kind = Value_Type.OBJECT;

	// Because x is incremented at the start instead of the bottom of the loop.
	x -= 1;
	for ; pos<len(file); pos+=1 {

		x += 1;
		
		// Skip to the first char.
		err := skip_whitespace(parser);
		if err.code != Error_Code.NO_ERROR {
			free_value(val);
			return nil, err;
		}

		c := file[pos];
		if c == '"' || c == '\'' {
			
			// Parse the value's key.
			key : ^Value;
			key, err = parse_string(parser);

			if err.code != Error_Code.NO_ERROR {
				free_value(val);
				return nil, err;
			}

			// Skip to the colon
			err = skip_whitespace(parser);
			if err.code != Error_Code.NO_ERROR {
				free_value(val);
				return nil, err;
			}

			// Make sure there's a colon

			c = file[pos];
			if c != ':' {
				free_value(val);
				return nil, Error{Error_Code.INVALID_CHAR, x, y};
			}
			x += 1;
			pos += 1;

			// Skip to the actual value.
			err = skip_whitespace(parser);
			if err.code != Error_Code.NO_ERROR {
				free_value(val);
				return nil, err;
			}

			// Set the actual property of the object.
			keys_val: ^Value;
			keys_val, err = parse_value(parser);

			if err.code != Error_Code.NO_ERROR {
				thingy, _ := val.object["name"];
				free_value(val);
				return nil, err;
			}
			val.object[key.str] = keys_val;
			append(&val.keystore, key.str);

			// Skip to the comma, or to the ending }
			err = skip_whitespace(parser);
			if err.code != Error_Code.NO_ERROR {
				free_value(val);
				return nil, err;
			}

			c = file[pos];

			if c == ',' do continue;
			else if c == '}' {
				pos += 1;
				x += 1;
				return val, NO_ERROR;
			}
		}


		free_value(val);
		return nil, Error{Error_Code.INVALID_CHAR, x, y};

	}
	
	free_value(val);
	return nil, Error{Error_Code.UNEXPECTED_END, 0, 0};

}

parse_array :: proc(using parser: ^Parser) -> (^Value, Error) {
	
	// We start at the [, so let's go ahead and move up.
	x += 1;
	pos += 1;

	val := new(Value);
	val.kind = Value_Type.ARRAY;

	// Because x is incremented at the start instead of the bottom of the loop.
	x -= 1;
	for ; pos<len(file); pos+=1 {

		x += 1;

		// Skip to the value.
		err := skip_whitespace(parser);
		if err.code != Error_Code.NO_ERROR {
			free_value(val);
			return nil, err;
		}

		// Set the actual property of the object.
		item: ^Value;
		item, err = parse_value(parser);

		if err.code != Error_Code.NO_ERROR {
			free_value(val);
			return nil, err;
		}

		append(&val.arr, item);

		// Skip to the comma, or to the ending ]
		err = skip_whitespace(parser);
		if err.code != Error_Code.NO_ERROR {
			free_value(val);
			return nil, err;
		}

		c := file[pos];

		if c == ',' do continue;
		else if c == ']' {
			pos += 1;
			x += 1;
			return val, NO_ERROR;
		}

		free_value(val);
		return nil, Error{Error_Code.INVALID_CHAR, x, y};

	}
	
	free_value(val);
	return nil, Error{Error_Code.UNEXPECTED_END, 0, 0};

}

when ODIN_OS == "windows" {
	c_ulong :: u32;
} else when size_of(uint) == 4 {
	c_ulong :: u32;
} else {
	c_ulong :: u64;
}

hex2int :: proc(str: string) -> rune {
	val: u32 = 0;
	for _c in str {
		c : u32 = cast(u32)_c;
		// transform hex character to the 4bit equivalent number, using the ascii table indexes
		if c >= '0' && c <= '9' do c = c - '0';
		else if c >= 'a' && c <='f' do c = c - 'a' + 10;
		else if c >= 'A' && c <='F' do c = c - 'A' + 10;    
		// shift 4 to make space for new digit, and add the 4 bits of the new digit 
		val = (val << 4) | (c & 0xF);
	}
	return cast(rune)val;
}

add_rune_to_str :: proc(r: rune, str: ^([dynamic]u8)) {
	chars, count := utf8.encode_rune(r);
	for i:=0; i<count; i+=1 do append(str, chars[i]);
}

is_surrogate_pair :: proc(a: rune, b: rune) -> bool {
	return a >= 0xD800 && a <= 0xDBFF && b >= 0xDC00 && b <= 0xDFFF;
}

parse_utf16_literal :: proc(using parser: ^Parser, str: ^([dynamic]u8)) {

	runes: [dynamic]rune;

	x-=1;
	for ; pos<len(file)-6; pos+=1 {
		x+=1;
		if(file[pos] == '\\' && file[pos+1] == 'u') {
			append(&runes, hex2int(file[pos+2..pos+6]));
			x += 5;
			pos += 5;
			continue;
		} else {
			break;
		}
	}

	for i:=0; i<len(runes);i+=1 {
		if (i < len(runes)-1 && is_surrogate_pair(runes[i], runes[i+1])) {add_rune_to_str(utf16.decode_surrogate_pair(runes[i], runes[i+1]), str); i += 1; }
		else do add_rune_to_str(runes[i], str);
	}

	free(runes);
}

parse_string :: proc(using parser: ^Parser) -> (^Value, Error) {
	
	// We start at the [, so let's go ahead and move up.
	x += 1;
	pos += 1;

	val := new(Value);
	val.kind = Value_Type.STRING;
	dynstr : [dynamic]u8;

	// Because x is incremented at the start instead of the bottom of the loop.
	x -= 1;
	for ; pos<len(file); pos+=1 {

		x += 1;

		if pos == len(file)-1 && file[pos] != '"' {

			free(dynstr);
			free_value(val);
			return nil, Error{Error_Code.UNEXPECTED_END, 0, 0};
		}

		cc := file[pos];

		if(cc != '"') {
			
			nc := file[pos+1];
			if(cc == '\\') {
				x += 1;
				pos += 1;
				match(nc) {
					case 'b': append(&dynstr, '\b');
					case 'f': append(&dynstr, '\f');
					case 'n': append(&dynstr, '\n');
					case 'r': append(&dynstr, '\r');
					case 't': append(&dynstr, '\t');
					case '"': fallthrough;
					case '\'': fallthrough;
					case '\\': fallthrough;
					case '/': append(&dynstr, nc);
					case 'u': {
						x -= 1;
						pos -= 1;
						parse_utf16_literal(parser, &dynstr);
						pos -= 1;
						x =- 1;
					}
					case: {
						free(dynstr);
						free_value(val);
						return nil, Error{Error_Code.INVALID_ESCAPE, x, y};
					}
				}
			} else if(cc == '\n') {
				free(dynstr);
				free_value(val);
				return nil, Error{Error_Code.INVALID_CHAR, x, y};
			} else {
				append(&dynstr, cc);
			}

		} else {
			x += 1;
			pos += 1;
			val.str = transmute(string)((cast(^raw.String)&dynstr)^);
			return val, NO_ERROR;
		}

	}

	// Should be unreachable, but better safe than sorry.

	fmt.fprintf(os.stderr, "json.odin:%d | Reached unreachable code!\n", #line);
	free(dynstr);
	free_value(val);
	return nil, Error{Error_Code.UNEXPECTED_END, 0, 0};

}

parse_number :: proc(using parser: ^Parser) -> (^Value, Error) {

	val := new(Value);
	//val.kind = Value_Type.;
	number_value_str : [dynamic]u8;

	has_decimal: bool = false;
	has_negative: bool = file[pos] == '-';

	if has_negative {
		pos += 1;
	} else {
		// Because x is incremented at the start instead of the bottom of the loop.
		x -= 1;
	}
	for ; pos<len(file); pos+=1 {
		x += 1;
		c := file[pos];
		if c == '.' {
			if(has_decimal) do return nil, Error{Error_Code.INVALID_CHAR, x, y};
			has_decimal = true;
			append(&number_value_str, c);
		} else if is_digit(c) do append(&number_value_str, c);
		else do break;
	}

	number_value_odin_str := transmute(string)((cast(^raw.String)&number_value_str)^);

	if(has_decimal) {
		val.kind = Value_Type.F64;
		val.float = strconv.parse_f64(number_value_odin_str) * (has_negative?-1:1);
	} else {
		val.kind = Value_Type.INT;
		val.integer = strconv.parse_int(number_value_odin_str) * (has_negative?-1:1);
	}

	free(number_value_str);
	return val, NO_ERROR;
}

parser_match :: proc(using parser: ^Parser, needle: string) -> bool {
	length := len(needle);
	if(len(file) > pos + length + 1) {
		if(file[pos..pos+length] == needle) {
			pos += length;
			x += length;
			return true;
		}
	}
	return false;
}

parse_null :: proc(using parser: ^Parser) -> (^Value, Error) {
	if parser_match(parser, "null") {

		val := new(Value);
		val.kind = Value_Type.NULL;
		return val, NO_ERROR;

	} else {

		return nil, Error{Error_Code.INVALID_CHAR, x, y};
	}
}

parse_bool :: proc(using parser: ^Parser) -> (^Value, Error) {
	if parser_match(parser, "true") {

		val := new(Value);
		val.kind = Value_Type.BOOL;
		val.boolean = true;
		return val, NO_ERROR;

	} else if parser_match(parser, "false") {

		val := new(Value);
		val.kind = Value_Type.BOOL;
		val.boolean = false;
		return val, NO_ERROR;

	} else {
		
		return nil, Error{Error_Code.INVALID_CHAR, x, y};
	}

}

parse_value :: proc(using parser: ^Parser) -> (^Value, Error) {

	err := skip_whitespace(parser);
	if err.code != Error_Code.NO_ERROR do return nil, err;

	c := file[pos];
	if c == '{' do return parse_object(parser);
	else if c == '[' do return parse_array(parser);
	else if c == '"' || c == '\'' do return parse_string(parser);
	else if is_digit(c) || c == '-' do return parse_number(parser);
	else if c == 'n' do return parse_null(parser);
	else if c == 't' || c == 'f' do return parse_bool(parser);
	else {
		return nil, Error{Error_Code.INVALID_CHAR, x, y};
	}

	return nil, Error{Error_Code.UNEXPECTED_END, 0, 0};

}