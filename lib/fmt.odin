export "core:fmt.odin"
import "os.odin"
import "str.odin"
import "core:math.odin"



/*
	PRINTP GUIDE
	---------------

	% prints next argument in order
	%(d) prints a specific index but DOES NOT change the index.
	%s(d) prints a specific index and DOES change the index to the next value.
	%% prints a '%'

	("% % % %1 % %% %s1% %", 1, 2, 3, 4)
	  -> "1 2 3 1 4 % 12 3"
*/

// fprint* procedures write to a file descriptor
fprintp :: proc(fd: os.Handle, fmt: string, args: ...any) -> int {
	data: [_BUFFER_SIZE]u8;
	buf := String_Buffer(data[..0]);
	sbprintp(&buf, fmt, ...args);
	res := string_buffer_data(buf);
	os.write(fd, res);
	return len(res);
}
// aprint* procedures return a string that was allocated with the current context
// They must be freed accordingly
aprintp :: proc(fmt: string, args: ...any) -> string {
	buf := String_Buffer(make([dynamic]u8));
	sbprintp(&buf, fmt, ...args);
	return to_string(buf);
}
// bprint* procedures return a string using a buffer from an array
bprintp :: proc(buf: []u8, fmt: string, args: ...any) -> string {
	sb := String_Buffer(buf[..0..len(buf)]);
	return sbprintp(&sb, fmt, ...args);
}
// print* procedures write to output streams - stdout or stderr
printp ::     proc(fmt: string, args: ...any) -> int { return fprintp(os.stdout, fmt, ...args); }
printp_err :: proc(fmt: string, args: ...any) -> int { return fprintp(os.stderr, fmt, ...args); }

/*
	% prints next argument in order
	%(d) prints a specific index but DOES NOT change the index.
	%s(d) prints a specific index and DOES change the index to the next value.
	%% prints a '%'
*/

sbprintp :: proc(b: ^String_Buffer, fmt: string, args: ...any) -> string {
	fi: Fmt_Info;
	arg_index: int = 1;
	end := len(fmt);
	was_prev_index := false;


	for i := 0; i < end; i += 1 {
		
		fi = Fmt_Info{buf = b, good_arg_index = true};

		prev_i := i;
		for i < end && fmt[i] != '%' {
			i += 1;
		}
		if i > prev_i {
			write_string(b, fmt[prev_i..i]);
		}
		if i >= end {
			break;
		}

		// Process a "verb"

		is_setting_pos := false;
		read_pos: int = -1;
		byte_to_write: u8 = 0;

		if fmt[i+1] == '%' {
			write_byte(b, '%');
			i += 1;
			continue;
		}

		if fmt[i+1] == 's' {
			is_setting_pos = true;
			i += 1;
		}
		
		if str.is_numeric(fmt[i+1]) {
			i += 1;
			read_pos = 0;
			new_read_pos : int = ---;

			number_gather_loop:
			for ; i < end && str.is_numeric(fmt[i]); i += 1 {

				new_read_pos = read_pos * 10 + int(fmt[i] - '0');

				if new_read_pos > len(args) {
					break number_gather_loop;
				} else do read_pos = new_read_pos;
			}
			i -= 1;
		} else if is_setting_pos {
			write_string(b, "%!(BAD ARGUMENT NUMBER)");
			continue;
		}

		if is_setting_pos do arg_index = read_pos + 1;
		if read_pos == -1 {
			read_pos = arg_index;
			arg_index += 1;
		}

		if read_pos > 0 && read_pos <= len(args) do fmt_value(&fi, args[read_pos-1], 'v');
		else do write_string(b, "%!(MISSING ARGUMENT)");
/*
		verb, w := utf8.decode_rune(fmt[i..]);
		i += w;

		if fmt[i+1] == '%' {
			write_byte(b, '%');
		} else if !fi.good_arg_index {
			write_string(b, "%!(BAD ARGUMENT NUMBER)");
		} else if arg_index >= len(args) {
			write_string(b, "%!(MISSING ARGUMENT)");
		} else {
			fmt_arg(&fi, args[arg_index], verb);
			arg_index += 1;
		}
		*/
	}

	return to_string(b^);
}
