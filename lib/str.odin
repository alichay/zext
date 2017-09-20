export "core:strings.odin";

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