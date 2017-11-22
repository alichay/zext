export "core:strings.odin";
export "core:strconv.odin";

cat :: proc(strs: ...string) -> string {
	total := 0;
	for s in strs do total += len(s);
	out := make([]u8, total);
	i := 0;
	for s in strs {
		for j in 0..len(s) {
			out[i] = s[j];
			i+=1;
		}
	}
	return string(out);
}

// Does the first string start with the second one?
starts_with :: inline proc(haystack, needle: string) -> bool {
	if len(haystack) < len(needle) do return false;
	for i in 0..len(needle) do if needle[i] != haystack[i] do return false;
	return true;
}
// Does the first string end with the second one?
ends_with :: inline proc(haystack, needle: string) -> bool {
	if len(haystack) < len(needle) do return false;
	hl, nl := len(haystack)-1, len(needle)-1;
	for i in 0..len(needle) do if needle[nl-i] != haystack[hl-i] do return false;
	return true;
}

dup :: proc(s: string) -> string {
	c := make([]u8, len(s));
	copy(c, cast([]u8)s);
	return string(c);
}

is_whitespace :: inline proc(char: rune) -> bool do return char == ' ' || char == '\t' || char == '\r' || char == '\n';

is_whitespace :: inline proc(char: u8) -> bool do return is_whitespace(cast(rune)char);


trim :: proc(s: string) -> string {
	b := 0;
	for i := 0; i < len(s); i += 1 {
		if !is_whitespace(s[i]) {
			b = i;
			break;
		}
	}
	for i := len(s)-1; i > 0; i -= 1 {
		if !is_whitespace(s[i]) {
			return s[b..i+1];
		}
	}
	return s;
}

import "core:fmt.odin";

// Splits the first string by the second.
// Note that "a,,b" split by "," will give ["a","b"] not ["a","","b"]
split :: proc(haystack, needle: string) -> [dynamic]string {

	assert(len(haystack)>0);
	assert(len(haystack)>len(needle));
	assert(len(needle)>0);

	strs: [dynamic]string;
	last_start := 0;

	for i := 0; i < len(haystack); i+=1 {

		is_match : bool = true;

		for j := 0; j < len(needle); j += 1 {
			if haystack[i+j] != needle[j] {
				is_match = false;
				break;
			}
		}

		if is_match {
			slice := haystack[last_start..i];
			if len(slice) > 0 do append(&strs, slice);
			i += len(needle) - 1;
			last_start = i + 1;
		}
	}

	slice := haystack[last_start..len(haystack)];
	if len(slice) > 0 do append(&strs, slice);

	return strs;
}

is_lower_latin :: inline proc(char: u8) -> bool do return char >= 'a' && char <= 'z';
is_upper_latin :: inline proc(char: u8) -> bool do return char >= 'A' && char <= 'Z';

is_digit :: inline proc(char: u8) -> bool do return char >= '0' && char <= '9';
is_numeric :: is_digit;
is_latin :: inline proc(char: u8) -> bool do return is_lower_latin(char) || is_upper_latin(char);
is_alpha :: is_latin;

is_alphanumeric :: inline proc(char: u8) -> bool do return is_alpha(char) || is_digit(char);