import "core:strings.odin";
import "core:os.odin";
import "core:fmt.odin";
import "core:mem.odin";


when ODIN_OS == "windows" {
	import win32 "core:sys/windows.odin";
	foreign import "system:kernel32.lib";
	foreign kernel32 {
		//_get_current_directory :: proc(buf_len: u32, buf: ^u8) #cc_std #link_name "GetCurrentDirectoryA" ---;
	}
} else {
	import "sys/posix/posix.odin";
	foreign import libc "system:c";
	foreign libc {
		_fork    :: proc() -> posix.pid                      #cc_c #link_name "fork"      ---;
		_pipe    :: proc(^os.Handle) -> i32                  #cc_c #link_name "pipe"      ---;
		_dup2    :: proc(os.Handle, os.Handle) -> i32        #cc_c #link_name "dup2"      ---;
		_execvp  :: proc(path: ^u8, args: ^^u8) -> i32       #cc_c #link_name "execvp"    ---;
		_wait    :: proc(rawptr) -> posix.pid                #cc_c #link_name "wait"      ---;
		_waitpid :: proc(posix.pid, ^i32, i32) -> posix.pid  #cc_c #link_name "waitpid"   ---;
		_nsleep  :: proc(dur, rem: ^posix.Time_Spec) -> i32  #cc_c #link_name "nanosleep" ---;
		_getpid  :: proc() -> posix.pid                      #cc_c #link_name "getpid"    ---;
	}
}

NS_SLEEP : posix.Nanosecond : posix.Nanosecond(1000000.0 * 100);

spawn :: proc(cb: proc(string), args: ...string) {

	// fmt.println(_kill(49514, 0));


	c_args := make([]^u8, len(args)+1);
	for s, i in args do c_args[i] = strings.new_c_string(s);
	c_args[len(args)] = nil;
	defer {
		for s in c_args do free(s);
		free(c_args);
	}

	when ODIN_OS == "windows" {
		_ := compile_assert(false);
	} else {

		pid_packet_size :: size_of(posix.pid) / size_of(u8) + 1;
	
		stream: [2]os.Handle;
		pid: posix.pid;

		if _pipe(&stream[0]) == -1 {
			fmt.println("Failed to create pipes.");
			return;
		}

		if pid = _fork(); pid == -1 {
			fmt.println("Failed to fork process.");
			return;
		}

		pid_data := make([]u8, pid_packet_size);

		if pid == 0 {
			_dup2(stream[1], os.stdout);
			os.close(stream[0]);
			os.close(stream[1]);
			(cast(^posix.pid)(&pid_data[0]))^ = _getpid();
			pid_data[pid_packet_size-1] = '\n';
			os.write(os.stdout, pid_data);


			fmt.println("REAL PID: ", pid);
			_execvp(c_args[0], &c_args[0]);
			fmt.println("Failed to start process.");

		} else {

			os.close(stream[1]);
			buf: [4096]u8;
			_, _ := os.read(stream[0], pid_data[0..len(pid_data)]);
			child_pid := (cast(^posix.pid)(&pid_data[0]))^;
			fmt.println("CHILD:", child_pid);

			looping := true;
			status: i32;
			i := 0;

			bytes: int;
			for looping {
				if _waitpid(child_pid, &status, 1) != 0 do looping = false;
				bytes, _ = os.read(stream[0], buf[..]);
				//fmt.println("OUT: ", strings.to_odin_string(&buf[0]), "END");
				data := string(mem.slice_ptr(&buf[0], bytes));
				//if data != "" do fmt.println("DATA:", data);
				if data != "" do cb(data);
				//fmt.println("LS", loop_state);

				sleep_time := posix.Time_Spec{0, NS_SLEEP};
				i = i + 1;
				_nsleep(&sleep_time, nil); // .25ms
			}
		}
	}
}
