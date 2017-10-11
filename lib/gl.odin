// Swapping argument orders:
//     (\^)*(i8|u8|i16|u16|i32|u32|i64|u64|f32|f64|rawptr|int|uint) ([\w_]+)
//     $3: $1$2

import "feature_test.odin";
import "core:fmt.odin";
import "str.odin";
import "os.odin";
export "core:opengl_constants.odin";


when feature_test.MICROSOFT {

	import win32 "core:sys/windows.odin";
	import "core:sys/wgl.odin";

	gl_library: win32.Hmodule;

	_initialize :: proc() #inline {
		
		c_str := str.new_c_string("opengl32.dll");
		defer free(c_str);

		gl_library = win32.load_library_a(c_str);
	}

	_set_proc_address :: proc(p: rawptr, name: string) {

		name_c_str := str.new_c_string(name);
		defer free(name_c_str);

		proc_ptr := wgl.get_proc_address(name_c_str);

		if proc_ptr == nil {

			proc_ptr = win32.get_proc_address(gl_library, name_c_str);
		}

		(cast(^rawptr)p)^ = proc_ptr;
	}

} else when feature_test.LINUX {

	gl_library: rawptr;

	_initialize :: proc() #inline {

		gl_library = os.dlopen("libGL.so", os.RTLD_NOW | os.RTLD_GLOBAL);

		if gl_library == nil {

			fmt.print("Failed to open the OpenGL shared library. Error message: ");
			fmt.println(os.dlerror());
			fmt.println("Exiting!");
			os.exit(1);
		}
	}

	_set_proc_address :: proc(p: rawptr, name: string) {
		(cast(^rawptr)p)^ = rawptr(os.dlsym(gl_library, name));
	}

} else when feature_test.APPLE {

	import cf "zext:sys/apple/core_foundation.odin";

	gl_framework: cf.Bundle_Ref;

	_initialize :: proc() #inline {

		gl_framework = cf.bundle_get_bundle_with_identifier("com.apple.opengl");

		if gl_framework == nil {
			fmt.println("Failed to open the OpenGL framework. Exiting!");
			os.exit(1);
		}
	}

	_set_proc_address :: proc(p: rawptr, name: string) {
		(cast(^rawptr)p)^ = rawptr(cf.bundle_get_function_pointer_for_name(gl_framework, name));
	}
}


load_up_to :: proc(major, minor : int) {
	_initialize();
	switch major*10+minor {
		case 45: load_4_5(); fallthrough;
		case 44: load_4_4(); fallthrough;
		case 43: load_4_3(); fallthrough;
		case 42: load_4_2(); fallthrough;
		case 41: load_4_1(); fallthrough;
		case 40: load_4_0(); fallthrough;
		case 33: load_3_3(); fallthrough;
		case 32: load_3_2(); fallthrough;
		case 31: load_3_1(); fallthrough;
		case 30: load_3_0(); fallthrough;
		case 21: load_2_1(); fallthrough;
		case 20: load_2_0(); fallthrough;
		case 15: load_1_5(); fallthrough;
		case 14: load_1_4(); fallthrough;
		case 13: load_1_3(); fallthrough;
		case 12: load_1_2(); fallthrough;
		case 11: load_1_1(); fallthrough;
		case 10: load_1_0();
	}
}

/* 
Type conversion overview: 
	typedef unsigned int GLenum;     -> u32
	typedef unsigned char GLboolean; -> u8
	typedef unsigned int GLbitfield; -> u32
	typedef signed char GLbyte;      -> i8
	typedef short GLshort;           -> i16
	typedef int GLint;               -> i32
	typedef unsigned char GLubyte;   -> u8
	typedef unsigned short GLushort; -> u16
	typedef unsigned int GLuint;     -> u32
	typedef int GLsizei;             -> i32
	typedef float GLfloat;           -> f32
	typedef double GLdouble;         -> f64
	typedef char GLchar;             -> u8
	typedef ptrdiff_t GLintptr;      -> int
	typedef ptrdiff_t GLsizeiptr;    -> int
	typedef int64_t GLint64;         -> i64
	typedef uint64_t GLuint64;       -> u64

	void*                            -> rawptr
*/

sync_t :: #type ^struct {};
debug_proc_t :: proc(source: u32, type_: u32, id: u32, severity: u32, length: i32, message: ^u8, userParam: rawptr) #cc_c;


// VERSION_1_0
cull_face:               proc(mode: u32)                                                                                                                   #cc_c;
front_face:              proc(mode: u32)                                                                                                                   #cc_c;
hint:                   proc(target: u32, mode: u32)                                                                                                      #cc_c;
line_width:              proc(width: f32)                                                                                                                  #cc_c;
point_size:              proc(size: f32)                                                                                                                   #cc_c;
polygon_mode:            proc(face: u32, mode: u32)                                                                                                        #cc_c;
scissor:                proc(x: i32, y: i32, width: i32, height: i32)                                                                                     #cc_c;
tex_parameter_f:          proc(target: u32, pname: u32, param: f32)                                                                                         #cc_c;
tex_parameter_fv:         proc(target: u32, pname: u32, params: ^f32)                                                                                       #cc_c;
tex_parameter_i:          proc(target: u32, pname: u32, param: i32)                                                                                         #cc_c;
tex_parameter_iv:         proc(target: u32, pname: u32, params: ^i32)                                                                                       #cc_c;
tex_image_1d:             proc(target: u32, level: i32, internalformat: i32, width: i32, border: i32, format: u32, type_: u32, pixels: rawptr)              #cc_c;
tex_image_2d:             proc(target: u32, level: i32, internalformat: i32, width: i32, height: i32, border: i32, format: u32, type_: u32, pixels: rawptr) #cc_c;
draw_buffer:             proc(buf: u32)                                                                                                                    #cc_c;
clear:                  proc(mask: u32)                                                                                                                   #cc_c;
clear_color:             proc(red: f32, green: f32, blue: f32, alpha: f32)                                                                                 #cc_c;
clear_stencil:           proc(s: i32)                                                                                                                      #cc_c;
clear_depth:             proc(depth: f64)                                                                                                                  #cc_c;
stencil_mask:            proc(mask: u32)                                                                                                                   #cc_c;
color_mask:              proc(red: u8, green: u8, blue: u8, alpha: u8)                                                                                     #cc_c;
depth_mask:              proc(flag: u8)                                                                                                                    #cc_c;
disable:                proc(cap: u32)                                                                                                                    #cc_c;
enable:                 proc(cap: u32)                                                                                                                    #cc_c;
finish:                 proc()                                                                                                                            #cc_c;
flush:                  proc()                                                                                                                            #cc_c;
blend_func:              proc(sfactor: u32, dfactor: u32)                                                                                                  #cc_c;
logic_op:                proc(opcode: u32)                                                                                                                 #cc_c;
stencil_func:            proc(func: u32, ref: i32, mask: u32)                                                                                              #cc_c;
stencil_op:              proc(fail: u32, zfail: u32, zpass: u32)                                                                                           #cc_c;
depth_func:              proc(func: u32)                                                                                                                   #cc_c;
pixel_store_f:            proc(pname: u32, param: f32)                                                                                                      #cc_c;
pixel_store_i:            proc(pname: u32, param: i32)                                                                                                      #cc_c;
read_buffer:             proc(src: u32)                                                                                                                    #cc_c;
read_pixels:             proc(x: i32, y: i32, width: i32, height: i32, format: u32, type_: u32, pixels: rawptr)                                            #cc_c;
get_boolean_v:            proc(pname: u32, data: ^u8)                                                                                                       #cc_c;
get_double_v:             proc(pname: u32, data: ^f64)                                                                                                      #cc_c;
get_error:               proc() -> u32                                                                                                                     #cc_c;
get_float_v:              proc(pname: u32, data: ^f32)                                                                                                      #cc_c;
get_integer_v:            proc(pname: u32, data: ^i32)                                                                                                      #cc_c;
get_string:              proc(name: u32) -> ^u8                                                                                                            #cc_c;
get_tex_image:            proc(target: u32,  level: i32, format: u32, type_: u32, pixels: rawptr)                                                           #cc_c;
get_tex_parameter_fv:      proc(target: u32, pname: u32, params: ^f32)                                                                                       #cc_c;
get_tex_parameter_iv:      proc(target: u32, pname: u32, params: ^i32)                                                                                       #cc_c;
get_tex_level_parameter_fv: proc(target: u32, level: i32, pname: u32, params: ^f32)                                                                           #cc_c;
get_tex_level_parameter_iv: proc(target: u32, level: i32, pname: u32, params: ^i32)                                                                           #cc_c;
is_enabled:              proc(cap: u32) -> u8                                                                                                              #cc_c;
depth_range:             proc(near: f64, far: f64)                                                                                                         #cc_c;
viewport:               proc(x: i32, y: i32, width: i32, height: i32)                                                                                     #cc_c;

load_1_0 :: proc() {
	_set_proc_address(&cull_face,               "glCullFace\x00");
	_set_proc_address(&front_face,              "glFrontFace\x00");
	_set_proc_address(&hint,                   "glHint\x00");
	_set_proc_address(&line_width,              "glLineWidth\x00");
	_set_proc_address(&point_size,              "glPointSize\x00");
	_set_proc_address(&polygon_mode,            "glPolygonMode\x00");
	_set_proc_address(&scissor,                "glScissor\x00");
	_set_proc_address(&tex_parameter_f,          "glTexParameterf\x00");
	_set_proc_address(&tex_parameter_fv,         "glTexParameterfv\x00");
	_set_proc_address(&tex_parameter_i,          "glTexParameteri\x00");
	_set_proc_address(&tex_parameter_iv,         "glTexParameteriv\x00");
	_set_proc_address(&tex_image_1d,             "glTexImage1D\x00");
	_set_proc_address(&tex_image_2d,             "glTexImage2D\x00");
	_set_proc_address(&draw_buffer,             "glDrawBuffer\x00");
	_set_proc_address(&clear,                  "glClear\x00");
	_set_proc_address(&clear_color,             "glClearColor\x00");
	_set_proc_address(&clear_stencil,           "glClearStencil\x00");
	_set_proc_address(&clear_depth,             "glClearDepth\x00");
	_set_proc_address(&stencil_mask,            "glStencilMask\x00");
	_set_proc_address(&color_mask,              "glColorMask\x00");
	_set_proc_address(&depth_mask,              "glDepthMask\x00");
	_set_proc_address(&disable,                "glDisable\x00");
	_set_proc_address(&enable,                 "glEnable\x00");
	_set_proc_address(&finish,                 "glFinish\x00");
	_set_proc_address(&flush,                  "glFlush\x00");
	_set_proc_address(&blend_func,              "glBlendFunc\x00");
	_set_proc_address(&logic_op,                "glLogicOp\x00");
	_set_proc_address(&stencil_func,            "glStencilFunc\x00");
	_set_proc_address(&stencil_op,              "glStencilOp\x00");
	_set_proc_address(&depth_func,              "glDepthFunc\x00");
	_set_proc_address(&pixel_store_f,            "glPixelStoref\x00");
	_set_proc_address(&pixel_store_i,            "glPixelStorei\x00");
	_set_proc_address(&read_buffer,             "glReadBuffer\x00");
	_set_proc_address(&read_pixels,             "glReadPixels\x00");
	_set_proc_address(&get_boolean_v,            "glGetBooleanv\x00");
	_set_proc_address(&get_double_v,             "glGetDoublev\x00");
	_set_proc_address(&get_error,               "glGetError\x00");
	_set_proc_address(&get_float_v,              "glGetFloatv\x00");
	_set_proc_address(&get_integer_v,            "glGetIntegerv\x00");
	_set_proc_address(&get_string,              "glGetString\x00");
	_set_proc_address(&get_tex_image,            "glGetTexImage\x00");
	_set_proc_address(&get_tex_parameter_fv,      "glGetTexParameterfv\x00");
	_set_proc_address(&get_tex_parameter_iv,      "glGetTexParameteriv\x00");
	_set_proc_address(&get_tex_level_parameter_fv, "glGetTexLevelParameterfv\x00");
	_set_proc_address(&get_tex_level_parameter_iv, "glGetTexLevelParameteriv\x00");
	_set_proc_address(&is_enabled,              "glIsEnabled\x00");
	_set_proc_address(&depth_range,             "glDepthRange\x00");
	_set_proc_address(&viewport,               "glViewport\x00");
}


// VERSION_1_1
draw_arrays:        proc(mode: u32, first: i32, count: i32)                                                                                     #cc_c;
draw_elements:      proc(mode: u32, count: i32, type_: u32, indices: rawptr)                                                                    #cc_c;
polygon_offset:     proc(factor: f32, units: f32)                                                                                               #cc_c;
copy_tex_image_1d:    proc(target: u32, level: i32, internalformat: u32, x: i32, y: i32, width: i32, border: i32)                                 #cc_c;
copy_tex_image_2d:    proc(target: u32, level: i32, internalformat: u32, x: i32, y: i32, width: i32, height: i32, border: i32)                    #cc_c;
copy_tex_sub_image_1d: proc(target: u32, level: i32, xoffset: i32, x: i32, y: i32, width: i32)                                                     #cc_c;
copy_tex_sub_image_2d: proc(target: u32, level: i32, xoffset: i32, yoffset: i32, x: i32, y: i32, width: i32, height: i32)                          #cc_c;
tex_sub_image_1d:     proc(target: u32, level: i32, xoffset: i32, width: i32, format: u32, type_: u32, pixels: rawptr)                            #cc_c;
tex_sub_image_2d:     proc(target: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, type_: u32, pixels: rawptr) #cc_c;
bind_texture:       proc(target: u32, texture: u32)                                                                                             #cc_c;
delete_textures:    proc(n: i32, textures: ^u32)                                                                                                #cc_c;
gen_textures:       proc(n: i32, textures: ^u32)                                                                                                #cc_c;
is_texture:         proc(texture: u32) -> u8                                                                                                    #cc_c;

load_1_1 :: proc() {
	_set_proc_address(&draw_arrays,        "glDrawArrays\x00");
	_set_proc_address(&draw_elements,      "glDrawElements\x00");
	_set_proc_address(&polygon_offset,     "glPolygonOffset\x00");
	_set_proc_address(&copy_tex_image_1d,    "glCopyTexImage1D\x00");
	_set_proc_address(&copy_tex_image_2d,    "glCopyTexImage2D\x00");
	_set_proc_address(&copy_tex_sub_image_1d, "glCopyTexSubImage1D\x00");
	_set_proc_address(&copy_tex_sub_image_2d, "glCopyTexSubImage2D\x00");
	_set_proc_address(&tex_sub_image_1d,     "glTexSubImage1D\x00");
	_set_proc_address(&tex_sub_image_2d,     "glTexSubImage2D\x00");
	_set_proc_address(&bind_texture,       "glBindTexture\x00");
	_set_proc_address(&delete_textures,    "glDeleteTextures\x00");
	_set_proc_address(&gen_textures,       "glGenTextures\x00");
	_set_proc_address(&is_texture,         "glIsTexture\x00");
}


// VERSION_1_2
draw_range_elements: proc(mode: u32, start: u32, end: u32, count: i32, type_: u32, indices: rawptr)                                                                        #cc_c;
tex_image_3d:        proc(target: u32, level: i32, internalformat: i32, width: i32, height: i32, depth: i32, border: i32, format: u32, type_: u32, pixels: rawptr)         #cc_c;
tex_sub_image_3d:     proc(target: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, type_: u32, pixels: rawptr) #cc_c;
copy_tex_sub_image_3d: proc(target: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, x: i32, y: i32, width: i32, height: i32)                                      #cc_c;

load_1_2 :: proc() {

	_set_proc_address(&draw_range_elements, "glDrawRangeElements\x00");
	_set_proc_address(&tex_image_3d,        "glTexImage3D\x00");
	_set_proc_address(&tex_sub_image_3d,     "glTexSubImage3D\x00");
	_set_proc_address(&copy_tex_sub_image_3d, "glCopyTexSubImage3D\x00");
}


// VERSION_1_3
active_texture:           proc(texture: u32)                                                                                                                                      #cc_c;
sample_coverage:          proc(value: f32, invert: u8)                                                                                                                            #cc_c;
compressed_tex_image_3d:    proc(target: u32, level: i32, internalformat: u32, width: i32, height: i32, depth: i32, border: i32, imageSize: i32, data: rawptr)                      #cc_c;
compressed_tex_image_2d:    proc(target: u32, level: i32, internalformat: u32, width: i32, height: i32, border: i32, imageSize: i32, data: rawptr)                                  #cc_c;
compressed_tex_image_1d:    proc(target: u32, level: i32, internalformat: u32, width: i32, border: i32, imageSize: i32, data: rawptr)                                               #cc_c;
compressed_tex_sub_image_3d: proc(target: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, imageSize: i32, data: rawptr) #cc_c;
compressed_tex_sub_image_2d: proc(target: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, imageSize: i32, data: rawptr)                           #cc_c;
compressed_tex_sub_image_1d: proc(target: u32, level: i32, xoffset: i32, width: i32, format: u32, imageSize: i32, data: rawptr)                                                      #cc_c;
get_compressed_tex_image:   proc(target: u32, level: i32, img: rawptr)                                                                                                              #cc_c;

load_1_3 :: proc() {
	_set_proc_address(&active_texture,           "glActiveTexture\x00");
	_set_proc_address(&sample_coverage,          "glSampleCoverage\x00");
	_set_proc_address(&compressed_tex_image_3d,    "glCompressedTexImage3D\x00");
	_set_proc_address(&compressed_tex_image_2d,    "glCompressedTexImage2D\x00");
	_set_proc_address(&compressed_tex_image_1d,    "glCompressedTexImage1D\x00");
	_set_proc_address(&compressed_tex_sub_image_3d, "glCompressedTexSubImage3D\x00");
	_set_proc_address(&compressed_tex_sub_image_2d, "glCompressedTexSubImage2D\x00");
	_set_proc_address(&compressed_tex_sub_image_1d, "glCompressedTexSubImage1D\x00");
	_set_proc_address(&get_compressed_tex_image,   "glGetCompressedTexImage\x00");
}


// VERSION_1_4
blend_func_separate: proc(sfactorRGB: u32, dfactorRGB: u32, sfactorAlpha: u32, dfactorAlpha: u32) #cc_c;
multi_draw_arrays:   proc(mode: u32, first: ^i32, count: ^i32, drawcount: i32)                    #cc_c;
multi_draw_elements: proc(mode: u32, count: ^i32, type_: u32, indices: ^rawptr, drawcount: i32)   #cc_c;
point_parameter_f:   proc(pname: u32, param: f32)                                                 #cc_c;
point_parameter_fv:  proc(pname: u32, params: ^f32)                                               #cc_c;
point_parameter_i:   proc(pname: u32, param: i32)                                                 #cc_c;
point_parameter_iv:  proc(pname: u32, params: ^i32)                                               #cc_c;
blend_color:        proc(red: f32, green: f32, blue: f32, alpha: f32)                            #cc_c;
blend_equation:     proc(mode: u32)                                                              #cc_c;


load_1_4 :: proc() {
	_set_proc_address(&blend_func_separate, "glBlendFuncSeparate\x00");
	_set_proc_address(&multi_draw_arrays,   "glMultiDrawArrays\x00");
	_set_proc_address(&multi_draw_elements, "glMultiDrawElements\x00");
	_set_proc_address(&point_parameter_f,   "glPointParameterf\x00");
	_set_proc_address(&point_parameter_fv,  "glPointParameterfv\x00");
	_set_proc_address(&point_parameter_i,   "glPointParameteri\x00");
	_set_proc_address(&point_parameter_iv,  "glPointParameteriv\x00");
	_set_proc_address(&blend_color,        "glBlendColor\x00");
	_set_proc_address(&blend_equation,     "glBlendEquation\x00");
}


// VERSION_1_5
gen_queries:           proc(n: i32, ids: ^u32)                                 #cc_c;
delete_queries:        proc(n: i32, ids: ^u32)                                 #cc_c;
is_query:              proc(id: u32) -> u8                                     #cc_c;
begin_query:           proc(target: u32, id: u32)                              #cc_c;
end_query:             proc(target: u32)                                       #cc_c;
get_query_iv:           proc(target: u32, pname: u32, params: ^i32)             #cc_c;
get_query_object_iv:     proc(id: u32, pname: u32, params: ^i32)                 #cc_c;
get_query_object_uiv:    proc(id: u32, pname: u32, params: ^u32)                 #cc_c;
bind_buffer:           proc(target: u32, buffer: u32)                          #cc_c;
delete_buffers:        proc(n: i32, buffers: ^u32)                             #cc_c;
gen_buffers:           proc(n: i32, buffers: ^u32)                             #cc_c;
is_buffer:             proc(buffer: u32) -> u8                                 #cc_c;
buffer_data:           proc(target: u32, size: int, data: rawptr, usage: u32)  #cc_c;
buffer_sub_data:        proc(target: u32, offset: int, size: int, data: rawptr) #cc_c;
get_buffer_sub_data:     proc(target: u32, offset: int, size: int, data: rawptr) #cc_c;
map_buffer:            proc(target: u32, access: u32) -> rawptr                #cc_c;
unmap_buffer:          proc(target: u32) -> u8                                 #cc_c;
get_buffer_parameter_iv: proc(target: u32, pname: u32, params: ^i32)             #cc_c;
get_buffer_pointer_v:    proc(target: u32, pname: u32, params: ^rawptr)          #cc_c;

load_1_5 :: proc() {
	_set_proc_address(&gen_queries,           "glGenQueries\x00");
	_set_proc_address(&delete_queries,        "glDeleteQueries\x00");
	_set_proc_address(&is_query,              "glIsQuery\x00");
	_set_proc_address(&begin_query,           "glBeginQuery\x00");
	_set_proc_address(&end_query,             "glEndQuery\x00");
	_set_proc_address(&get_query_iv,           "glGetQueryiv\x00");
	_set_proc_address(&get_query_object_iv,     "glGetQueryObjectiv\x00");
	_set_proc_address(&get_query_object_uiv,    "glGetQueryObjectuiv\x00");
	_set_proc_address(&bind_buffer,           "glBindBuffer\x00");
	_set_proc_address(&delete_buffers,        "glDeleteBuffers\x00");
	_set_proc_address(&gen_buffers,           "glGenBuffers\x00");
	_set_proc_address(&is_buffer,             "glIsBuffer\x00");
	_set_proc_address(&buffer_data,           "glBufferData\x00");
	_set_proc_address(&buffer_sub_data,        "glBufferSubData\x00");
	_set_proc_address(&get_buffer_sub_data,     "glGetBufferSubData\x00");
	_set_proc_address(&map_buffer,            "glMapBuffer\x00");
	_set_proc_address(&unmap_buffer,          "glUnmapBuffer\x00");
	_set_proc_address(&get_buffer_parameter_iv, "glGetBufferParameteriv\x00");
	_set_proc_address(&get_buffer_pointer_v,    "glGetBufferPointerv\x00");
}


// VERSION_2_0
blend_equation_separate:    proc(modeRGB: u32, modeAlpha: u32)                                                             #cc_c;
draw_buffers:              proc(n: i32, bufs: ^u32)                                                                       #cc_c;
stencil_op_separate:        proc(face: u32, sfail: u32, dpfail: u32, dppass: u32)                                          #cc_c;
stencil_func_separate:      proc(face: u32, func: u32, ref: i32, mask: u32)                                                #cc_c;
stencil_mask_separate:      proc(face: u32, mask: u32)                                                                     #cc_c;
attach_shader:             proc(program: u32, shader: u32)                                                                #cc_c;
bind_attrib_location:       proc(program: u32, index: u32, name: ^u8)                                                      #cc_c;
compile_shader:            proc(shader: u32)                                                                              #cc_c;
create_program:            proc() -> u32                                                                                  #cc_c;
create_shader:             proc(type_: u32) -> u32                                                                        #cc_c;
delete_program:            proc(program: u32)                                                                             #cc_c;
delete_shader:             proc(shader: u32)                                                                              #cc_c;
detach_shader:             proc(program: u32, shader: u32)                                                                #cc_c;
disable_vertex_attrib_array: proc(index: u32)                                                                               #cc_c;
enable_vertex_attrib_array:  proc(index: u32)                                                                               #cc_c;
get_active_attrib:          proc(program: u32, index: u32, bufSize: i32, length: ^i32, size: ^i32, type_: ^u32, name: ^u8) #cc_c;
get_active_uniform:         proc(program: u32, index: u32, bufSize: i32, length: ^i32, size: ^i32, type_: ^u32, name: ^u8) #cc_c;
get_attached_shaders:       proc(program: u32, maxCount: i32, count: ^i32, shaders: ^u32)                                  #cc_c;
get_attrib_location:        proc(program: u32, name: ^u8) -> i32                                                           #cc_c;
get_program_iv:             proc(program: u32, pname: u32, params: ^i32)                                                   #cc_c;
get_program_info_log:        proc(program: u32, bufSize: i32, length: ^i32, infoLog: ^u8)                                   #cc_c;
get_shader_iv:              proc(shader: u32, pname: u32, params: ^i32)                                                    #cc_c;
get_shader_info_log:         proc(shader: u32, bufSize: i32, length: ^i32, infoLog: ^u8)                                    #cc_c;
get_shader_source:          proc(shader: u32, bufSize: i32, length: ^i32, source: ^u8)                                     #cc_c;
get_uniform_location:       proc(program: u32, name: ^u8) -> i32                                                           #cc_c;
get_uniform_fv:             proc(program: u32, location: i32, params: ^f32)                                                #cc_c;
get_uniform_iv:             proc(program: u32, location: i32, params: ^i32)                                                #cc_c;
get_vertex_attrib_dv:        proc(index: u32, pname: u32, params: ^f64)                                                     #cc_c;
get_vertex_attrib_fv:        proc(index: u32, pname: u32, params: ^f32)                                                     #cc_c;
get_vertex_attrib_iv:        proc(index: u32, pname: u32, params: ^i32)                                                     #cc_c;
get_vertex_attrib_pointer_v:  proc(index: u32, pname: u32, pointer: ^rawptr)                                                 #cc_c;
is_program:                proc(program: u32) -> u8                                                                       #cc_c;
is_shader:                 proc(shader: u32) -> u8                                                                        #cc_c;
link_program:              proc(program: u32)                                                                             #cc_c;
shader_source:             proc(shader: u32, count: i32, string: ^^u8, length: ^i32)                                      #cc_c;
use_program:               proc(program: u32)                                                                             #cc_c;
uniform_1f:                proc(location: i32, v0: f32)                                                                   #cc_c;
uniform_2f:                proc(location: i32, v0: f32, v1: f32)                                                          #cc_c;
uniform_3f:                proc(location: i32, v0: f32, v1: f32, v2: f32)                                                 #cc_c;
uniform_4f:                proc(location: i32, v0: f32, v1: f32, v2: f32, v3: f32)                                        #cc_c;
uniform_1i:                proc(location: i32, v0: i32)                                                                   #cc_c;
uniform_2i:                proc(location: i32, v0: i32, v1: i32)                                                          #cc_c;
uniform_3i:                proc(location: i32, v0: i32, v1: i32, v2: i32)                                                 #cc_c;
uniform_4i:                proc(location: i32, v0: i32, v1: i32, v2: i32, v3: i32)                                        #cc_c;
uniform_1fv:               proc(location: i32, count: i32, value: ^f32)                                                   #cc_c;
uniform_2fv:               proc(location: i32, count: i32, value: ^f32)                                                   #cc_c;
uniform_3fv:               proc(location: i32, count: i32, value: ^f32)                                                   #cc_c;
uniform_4fv:               proc(location: i32, count: i32, value: ^f32)                                                   #cc_c;
uniform_1iv:               proc(location: i32, count: i32, value: ^i32)                                                   #cc_c;
uniform_2iv:               proc(location: i32, count: i32, value: ^i32)                                                   #cc_c;
uniform_3iv:               proc(location: i32, count: i32, value: ^i32)                                                   #cc_c;
uniform_4iv:               proc(location: i32, count: i32, value: ^i32)                                                   #cc_c;
uniform_matrix_2fv:         proc(location: i32, count: i32, transpose: u8, value: ^f32)                                    #cc_c;
uniform_matrix_3fv:         proc(location: i32, count: i32, transpose: u8, value: ^f32)                                    #cc_c;
uniform_matrix_4fv:         proc(location: i32, count: i32, transpose: u8, value: ^f32)                                    #cc_c;
validate_program:          proc(program: u32)                                                                             #cc_c;
vertex_attrib_1d:           proc(index: u32, x: f64)                                                                       #cc_c;
vertex_attrib_1dv:          proc(index: u32, v: ^f64)                                                                      #cc_c;
vertex_attrib_1f:           proc(index: u32, x: f32)                                                                       #cc_c;
vertex_attrib_1fv:          proc(index: u32, v: ^f32)                                                                      #cc_c;
vertex_attrib_1s:           proc(index: u32, x: i16)                                                                       #cc_c;
vertex_attrib_1sv:          proc(index: u32, v: ^i16)                                                                      #cc_c;
vertex_attrib_2d:           proc(index: u32, x: f64, y: f64)                                                               #cc_c;
vertex_attrib_2dv:          proc(index: u32, v: ^f64)                                                                      #cc_c;
vertex_attrib_2f:           proc(index: u32, x: f32, y: f32)                                                               #cc_c;
vertex_attrib_2fv:          proc(index: u32, v: ^f32)                                                                      #cc_c;
vertex_attrib_2s:           proc(index: u32, x: i16, y: i16)                                                               #cc_c;
vertex_attrib_2sv:          proc(index: u32, v: ^i16)                                                                      #cc_c;
vertex_attrib_3d:           proc(index: u32, x: f64, y: f64, z: f64)                                                       #cc_c;
vertex_attrib_3dv:          proc(index: u32, v: ^f64)                                                                      #cc_c;
vertex_attrib_3f:           proc(index: u32, x: f32, y: f32, z: f32)                                                       #cc_c;
vertex_attrib_3fv:          proc(index: u32, v: ^f32)                                                                      #cc_c;
vertex_attrib_3s:           proc(index: u32, x: i16, y: i16, z: i16)                                                       #cc_c;
vertex_attrib_3sv:          proc(index: u32, v: ^i16)                                                                      #cc_c;
vertex_attrib_4n_bv:         proc(index: u32, v: ^i8)                                                                       #cc_c;
vertex_attrib_4n_iv:         proc(index: u32, v: ^i32)                                                                      #cc_c;
vertex_attrib_4n_sv:         proc(index: u32, v: ^i16)                                                                      #cc_c;
vertex_attrib_4n_ub:         proc(index: u32, x: u8, y: u8, z: u8, w: u8)                                                   #cc_c;
vertex_attrib_4n_ubv:        proc(index: u32, v: ^u8)                                                                       #cc_c;
vertex_attrib_4n_uiv:        proc(index: u32, v: ^u32)                                                                      #cc_c;
vertex_attrib_4n_usv:        proc(index: u32, v: ^u16)                                                                      #cc_c;
vertex_attrib_4bv:          proc(index: u32, v: ^i8)                                                                       #cc_c;
vertex_attrib_4d:           proc(index: u32, x: f64, y: f64, z: f64, w: f64)                                               #cc_c;
vertex_attrib_4dv:          proc(index: u32, v: ^f64)                                                                      #cc_c;
vertex_attrib_4f:           proc(index: u32, x: f32, y: f32, z: f32, w: f32)                                               #cc_c;
vertex_attrib_4fv:          proc(index: u32, v: ^f32)                                                                      #cc_c;
vertex_attrib_4iv:          proc(index: u32, v: ^i32)                                                                      #cc_c;
vertex_attrib_4s:           proc(index: u32, x: i16, y: i16, z: i16, w: i16)                                               #cc_c;
vertex_attrib_4sv:          proc(index: u32, v: ^i16)                                                                      #cc_c;
vertex_attrib_4ubv:         proc(index: u32, v: ^u8)                                                                       #cc_c;
vertex_attrib_4uiv:         proc(index: u32, v: ^u32)                                                                      #cc_c;
vertex_attrib_4usv:         proc(index: u32, v: ^u16)                                                                      #cc_c;
vertex_attrib_pointer:      proc(index: u32, size: i32, type_: u32, normalized: u8, stride: i32, pointer: rawptr)          #cc_c;

load_2_0 :: proc() {
	_set_proc_address(&blend_equation_separate,    "glBlendEquationSeparate\x00");
	_set_proc_address(&draw_buffers,              "glDrawBuffers\x00");
	_set_proc_address(&stencil_op_separate,        "glStencilOpSeparate\x00");
	_set_proc_address(&stencil_func_separate,      "glStencilFuncSeparate\x00");
	_set_proc_address(&stencil_mask_separate,      "glStencilMaskSeparate\x00");
	_set_proc_address(&attach_shader,             "glAttachShader\x00");
	_set_proc_address(&bind_attrib_location,       "glBindAttribLocation\x00");
	_set_proc_address(&compile_shader,            "glCompileShader\x00");
	_set_proc_address(&create_program,            "glCreateProgram\x00");
	_set_proc_address(&create_shader,             "glCreateShader\x00");
	_set_proc_address(&delete_program,            "glDeleteProgram\x00");
	_set_proc_address(&delete_shader,             "glDeleteShader\x00");
	_set_proc_address(&detach_shader,             "glDetachShader\x00");
	_set_proc_address(&disable_vertex_attrib_array, "glDisableVertexAttribArray\x00");
	_set_proc_address(&enable_vertex_attrib_array,  "glEnableVertexAttribArray\x00");
	_set_proc_address(&get_active_attrib,          "glGetActiveAttrib\x00");
	_set_proc_address(&get_active_uniform,         "glGetActiveUniform\x00");
	_set_proc_address(&get_attached_shaders,       "glGetAttachedShaders\x00");
	_set_proc_address(&get_attrib_location,        "glGetAttribLocation\x00");
	_set_proc_address(&get_program_iv,             "glGetProgramiv\x00");
	_set_proc_address(&get_program_info_log,        "glGetProgramInfoLog\x00");
	_set_proc_address(&get_shader_iv,              "glGetShaderiv\x00");
	_set_proc_address(&get_shader_info_log,         "glGetShaderInfoLog\x00");
	_set_proc_address(&get_shader_source,          "glGetShaderSource\x00");
	_set_proc_address(&get_uniform_location,       "glGetUniformLocation\x00");
	_set_proc_address(&get_uniform_fv,             "glGetUniformfv\x00");
	_set_proc_address(&get_uniform_iv,             "glGetUniformiv\x00");
	_set_proc_address(&get_vertex_attrib_dv,        "glGetVertexAttribdv\x00");
	_set_proc_address(&get_vertex_attrib_fv,        "glGetVertexAttribfv\x00");
	_set_proc_address(&get_vertex_attrib_iv,        "glGetVertexAttribiv\x00");
	_set_proc_address(&get_vertex_attrib_pointer_v,  "glGetVertexAttribPointerv\x00");
	_set_proc_address(&is_program,                "glIsProgram\x00");
	_set_proc_address(&is_shader,                 "glIsShader\x00");
	_set_proc_address(&link_program,              "glLinkProgram\x00");
	_set_proc_address(&shader_source,             "glShaderSource\x00");
	_set_proc_address(&use_program,               "glUseProgram\x00");
	_set_proc_address(&uniform_1f,                "glUniform1f\x00");
	_set_proc_address(&uniform_2f,                "glUniform2f\x00");
	_set_proc_address(&uniform_3f,                "glUniform3f\x00");
	_set_proc_address(&uniform_4f,                "glUniform4f\x00");
	_set_proc_address(&uniform_1i,                "glUniform1i\x00");
	_set_proc_address(&uniform_2i,                "glUniform2i\x00");
	_set_proc_address(&uniform_3i,                "glUniform3i\x00");
	_set_proc_address(&uniform_4i,                "glUniform4i\x00");
	_set_proc_address(&uniform_1fv,               "glUniform1fv\x00");
	_set_proc_address(&uniform_2fv,               "glUniform2fv\x00");
	_set_proc_address(&uniform_3fv,               "glUniform3fv\x00");
	_set_proc_address(&uniform_4fv,               "glUniform4fv\x00");
	_set_proc_address(&uniform_1iv,               "glUniform1iv\x00");
	_set_proc_address(&uniform_2iv,               "glUniform2iv\x00");
	_set_proc_address(&uniform_3iv,               "glUniform3iv\x00");
	_set_proc_address(&uniform_4iv,               "glUniform4iv\x00");
	_set_proc_address(&uniform_matrix_2fv,         "glUniformMatrix2fv\x00");
	_set_proc_address(&uniform_matrix_3fv,         "glUniformMatrix3fv\x00");
	_set_proc_address(&uniform_matrix_4fv,         "glUniformMatrix4fv\x00");
	_set_proc_address(&validate_program,          "glValidateProgram\x00");
	_set_proc_address(&vertex_attrib_1d,           "glVertexAttrib1d\x00");
	_set_proc_address(&vertex_attrib_1dv,          "glVertexAttrib1dv\x00");
	_set_proc_address(&vertex_attrib_1f,           "glVertexAttrib1f\x00");
	_set_proc_address(&vertex_attrib_1fv,          "glVertexAttrib1fv\x00");
	_set_proc_address(&vertex_attrib_1s,           "glVertexAttrib1s\x00");
	_set_proc_address(&vertex_attrib_1sv,          "glVertexAttrib1sv\x00");
	_set_proc_address(&vertex_attrib_2d,           "glVertexAttrib2d\x00");
	_set_proc_address(&vertex_attrib_2dv,          "glVertexAttrib2dv\x00");
	_set_proc_address(&vertex_attrib_2f,           "glVertexAttrib2f\x00");
	_set_proc_address(&vertex_attrib_2fv,          "glVertexAttrib2fv\x00");
	_set_proc_address(&vertex_attrib_2s,           "glVertexAttrib2s\x00");
	_set_proc_address(&vertex_attrib_2sv,          "glVertexAttrib2sv\x00");
	_set_proc_address(&vertex_attrib_3d,           "glVertexAttrib3d\x00");
	_set_proc_address(&vertex_attrib_3dv,          "glVertexAttrib3dv\x00");
	_set_proc_address(&vertex_attrib_3f,           "glVertexAttrib3f\x00");
	_set_proc_address(&vertex_attrib_3fv,          "glVertexAttrib3fv\x00");
	_set_proc_address(&vertex_attrib_3s,           "glVertexAttrib3s\x00");
	_set_proc_address(&vertex_attrib_3sv,          "glVertexAttrib3sv\x00");
	_set_proc_address(&vertex_attrib_4n_bv,         "glVertexAttrib4Nbv\x00");
	_set_proc_address(&vertex_attrib_4n_iv,         "glVertexAttrib4Niv\x00");
	_set_proc_address(&vertex_attrib_4n_sv,         "glVertexAttrib4Nsv\x00");
	_set_proc_address(&vertex_attrib_4n_ub,         "glVertexAttrib4Nub\x00");
	_set_proc_address(&vertex_attrib_4n_ubv,        "glVertexAttrib4Nubv\x00");
	_set_proc_address(&vertex_attrib_4n_uiv,        "glVertexAttrib4Nuiv\x00");
	_set_proc_address(&vertex_attrib_4n_usv,        "glVertexAttrib4Nusv\x00");
	_set_proc_address(&vertex_attrib_4bv,          "glVertexAttrib4bv\x00");
	_set_proc_address(&vertex_attrib_4d,           "glVertexAttrib4d\x00");
	_set_proc_address(&vertex_attrib_4dv,          "glVertexAttrib4dv\x00");
	_set_proc_address(&vertex_attrib_4f,           "glVertexAttrib4f\x00");
	_set_proc_address(&vertex_attrib_4fv,          "glVertexAttrib4fv\x00");
	_set_proc_address(&vertex_attrib_4iv,          "glVertexAttrib4iv\x00");
	_set_proc_address(&vertex_attrib_4s,           "glVertexAttrib4s\x00");
	_set_proc_address(&vertex_attrib_4sv,          "glVertexAttrib4sv\x00");
	_set_proc_address(&vertex_attrib_4ubv,         "glVertexAttrib4ubv\x00");
	_set_proc_address(&vertex_attrib_4uiv,         "glVertexAttrib4uiv\x00");
	_set_proc_address(&vertex_attrib_4usv,         "glVertexAttrib4usv\x00");
	_set_proc_address(&vertex_attrib_pointer,      "glVertexAttribPointer\x00");
}


// VERSION_2_1
uniform_matrix_2x3fv: proc(location: i32, count: i32, transpose: u8, value: ^f32) #cc_c;
uniform_matrix_3x2fv: proc(location: i32, count: i32, transpose: u8, value: ^f32) #cc_c;
uniform_matrix_2x4fv: proc(location: i32, count: i32, transpose: u8, value: ^f32) #cc_c;
uniform_matrix_4x2fv: proc(location: i32, count: i32, transpose: u8, value: ^f32) #cc_c;
uniform_matrix_3x4fv: proc(location: i32, count: i32, transpose: u8, value: ^f32) #cc_c;
uniform_matrix_4x3fv: proc(location: i32, count: i32, transpose: u8, value: ^f32) #cc_c;

load_2_1 :: proc() {
	_set_proc_address(&uniform_matrix_2x3fv, "glUniformMatrix2x3fv\x00");
	_set_proc_address(&uniform_matrix_3x2fv, "glUniformMatrix3x2fv\x00");
	_set_proc_address(&uniform_matrix_2x4fv, "glUniformMatrix2x4fv\x00");
	_set_proc_address(&uniform_matrix_4x2fv, "glUniformMatrix4x2fv\x00");
	_set_proc_address(&uniform_matrix_3x4fv, "glUniformMatrix3x4fv\x00");
	_set_proc_address(&uniform_matrix_4x3fv, "glUniformMatrix4x3fv\x00");
}


// VERSION_3_0
color_mask_i:                          proc(index: u32, r: u8, g: u8, b: u8, a: u8)                                                                                 #cc_c;
get_boolean_i_v:                       proc(target: u32, index: u32, data: ^u8)                                                                                     #cc_c;
get_integer_i_v:                       proc(target: u32, index: u32, data: ^i32)                                                                                    #cc_c;
enable_i:                             proc(target: u32, index: u32)                                                                                                #cc_c;
disable_i:                            proc(target: u32, index: u32)                                                                                                #cc_c;
is_enabled_i:                          proc(target: u32, index: u32) -> u8                                                                                          #cc_c;
begin_transform_feedback:              proc(primitiveMode: u32)                                                                                                     #cc_c;
end_transform_feedback:                proc()                                                                                                                       #cc_c;
bind_buffer_range:                     proc(target: u32, index: u32, buffer: u32, offset: int, size: int)                                                           #cc_c;
bind_buffer_base:                      proc(target: u32, index: u32, buffer: u32)                                                                                   #cc_c;
transform_feedback_varyings:           proc(program: u32, count: i32, varyings: ^u8, bufferMode: u32)                                                               #cc_c;
get_transform_feedback_varying:         proc(program: u32, index: u32, bufSize: i32, length: ^i32, size: ^i32, type_: ^u32, name: ^u8)                               #cc_c;
clamp_color:                          proc(target: u32, clamp: u32)                                                                                                #cc_c;
begin_conditional_render:              proc(id: u32, mode: u32)                                                                                                     #cc_c;
end_conditional_render:                proc()                                                                                                                       #cc_c;
vertex_attrib_i_pointer:                proc(index: u32, size: i32, type_: u32, stride: i32, pointer: rawptr)                                                        #cc_c;
get_vertex_attrib_iiv:                  proc(index: u32, pname: u32, params: ^i32)                                                                                   #cc_c;
get_vertex_attrib_iuiv:                 proc(index: u32, pname: u32, params: ^u32)                                                                                   #cc_c;
vertex_attrib_i1i:                     proc(index: u32, x: i32)                                                                                                     #cc_c;
vertex_attrib_i2i:                     proc(index: u32, x: i32, y: i32)                                                                                             #cc_c;
vertex_attrib_i3i:                     proc(index: u32, x: i32, y: i32, z: i32)                                                                                     #cc_c;
vertex_attrib_i4i:                     proc(index: u32, x: i32, y: i32, z: i32, w: i32)                                                                             #cc_c;
vertex_attrib_i1ui:                    proc(index: u32, x: u32)                                                                                                     #cc_c;
vertex_attrib_i2ui:                    proc(index: u32, x: u32, y: u32)                                                                                             #cc_c;
vertex_attrib_i3ui:                    proc(index: u32, x: u32, y: u32, z: u32)                                                                                     #cc_c;
vertex_attrib_i4ui:                    proc(index: u32, x: u32, y: u32, z: u32, w: u32)                                                                             #cc_c;
vertex_attrib_i1iv:                    proc(index: u32, v: ^i32)                                                                                                    #cc_c;
vertex_attrib_i2iv:                    proc(index: u32, v: ^i32)                                                                                                    #cc_c;
vertex_attrib_i3iv:                    proc(index: u32, v: ^i32)                                                                                                    #cc_c;
vertex_attrib_i4iv:                    proc(index: u32, v: ^i32)                                                                                                    #cc_c;
vertex_attrib_i1uiv:                   proc(index: u32, v: ^u32)                                                                                                    #cc_c;
vertex_attrib_i2uiv:                   proc(index: u32, v: ^u32)                                                                                                    #cc_c;
vertex_attrib_i3uiv:                   proc(index: u32, v: ^u32)                                                                                                    #cc_c;
vertex_attrib_i4uiv:                   proc(index: u32, v: ^u32)                                                                                                    #cc_c;
vertex_attrib_i4bv:                    proc(index: u32, v: ^i8)                                                                                                     #cc_c;
vertex_attrib_i4sv:                    proc(index: u32, v: ^i16)                                                                                                    #cc_c;
vertex_attrib_i4ubv:                   proc(index: u32, v: ^u8)                                                                                                     #cc_c;
vertex_attrib_i4usv:                   proc(index: u32, v: ^u16)                                                                                                    #cc_c;
get_uniform_uiv:                       proc(program: u32, location: i32, params: ^u32)                                                                              #cc_c;
bind_frag_data_location:                proc(program: u32, color: u32, name: ^u8)                                                                                    #cc_c;
get_frag_data_location:                 proc(program: u32, name: ^u8) -> i32                                                                                         #cc_c;
uniform_1ui:                          proc(location: i32, v0: u32)                                                                                                 #cc_c;
uniform_2ui:                          proc(location: i32, v0: u32, v1: u32)                                                                                        #cc_c;
uniform_3ui:                          proc(location: i32, v0: u32, v1: u32, v2: u32)                                                                               #cc_c;
uniform_4ui:                          proc(location: i32, v0: u32, v1: u32, v2: u32, v3: u32)                                                                      #cc_c;
uniform_1uiv:                         proc(location: i32, count: i32, value: ^u32)                                                                                 #cc_c;
uniform_2uiv:                         proc(location: i32, count: i32, value: ^u32)                                                                                 #cc_c;
uniform_3uiv:                         proc(location: i32, count: i32, value: ^u32)                                                                                 #cc_c;
uniform_4uiv:                         proc(location: i32, count: i32, value: ^u32)                                                                                 #cc_c;
tex_parameter_iiv:                     proc(target: u32, pname: u32, params: ^i32)                                                                                  #cc_c;
tex_parameter_iuiv:                    proc(target: u32, pname: u32, params: ^u32)                                                                                  #cc_c;
get_tex_parameter_iiv:                  proc(target: u32, pname: u32, params: ^i32)                                                                                  #cc_c;
get_tex_parameter_iuiv:                 proc(target: u32, pname: u32, params: ^u32)                                                                                  #cc_c;
clear_buffer_iv:                       proc(buffer: u32, drawbuffer: i32, value: ^i32)                                                                              #cc_c;
clear_buffer_uiv:                      proc(buffer: u32, drawbuffer: i32, value: ^u32)                                                                              #cc_c;
clear_buffer_fv:                       proc(buffer: u32, drawbuffer: i32, value: ^f32)                                                                              #cc_c;
clear_bufferfi:                       proc(buffer: u32, drawbuffer: i32, depth: f32, stencil: i32) -> rawptr                                                       #cc_c;
get_string_i:                          proc(name: u32, index: u32) -> u8                                                                                            #cc_c;
is_renderbuffer:                      proc(renderbuffer: u32) -> u8                                                                                                #cc_c;
bind_renderbuffer:                    proc(target: u32, renderbuffer: u32)                                                                                         #cc_c;
delete_renderbuffers:                 proc(n: i32, renderbuffers: ^u32)                                                                                            #cc_c;
gen_renderbuffers:                    proc(n: i32, renderbuffers: ^u32)                                                                                            #cc_c;
renderbuffer_storage:                 proc(target: u32, internalformat: u32, width: i32, height: i32)                                                              #cc_c;
get_renderbuffer_parameter_iv:          proc(target: u32, pname: u32, params: ^i32)                                                                                  #cc_c;
is_framebuffer:                       proc(framebuffer: u32) -> u8                                                                                                 #cc_c;
bind_framebuffer:                     proc(target: u32, framebuffer: u32)                                                                                          #cc_c;
delete_framebuffers:                  proc(n: i32, framebuffers: ^u32)                                                                                             #cc_c;
gen_framebuffers:                     proc(n: i32, framebuffers: ^u32)                                                                                             #cc_c;
check_framebuffer_status:              proc(target: u32) -> u32                                                                                                     #cc_c;
framebuffer_texture_1d:                proc(target: u32, attachment: u32, textarget: u32, texture: u32, level: i32)                                                 #cc_c;
framebuffer_texture_2d:                proc(target: u32, attachment: u32, textarget: u32, texture: u32, level: i32)                                                 #cc_c;
framebuffer_texture_3d:                proc(target: u32, attachment: u32, textarget: u32, texture: u32, level: i32, zoffset: i32)                                   #cc_c;
framebuffer_renderbuffer:             proc(target: u32, attachment: u32, renderbuffertarget: u32, renderbuffer: u32)                                               #cc_c;
get_framebuffer_attachment_parameter_iv: proc(target: u32, attachment: u32, pname: u32, params: ^i32)                                                                 #cc_c;
generate_mipmap:                      proc(target: u32)                                                                                                            #cc_c;
blit_framebuffer:                     proc(srcX0: i32, srcY0: i32, srcX1: i32, srcY1: i32, dstX0: i32, dstY0: i32, dstX1: i32, dstY1: i32, mask: u32, filter: u32) #cc_c;
renderbuffer_storage_multisample:      proc(target: u32, samples: i32, internalformat: u32, width: i32, height: i32)                                                #cc_c;
framebuffer_texture_layer:             proc(target: u32, attachment: u32, texture: u32, level: i32, layer: i32)                                                     #cc_c;
map_buffer_range:                      proc(target: u32, offset: int, length: int, access: u32) -> rawptr                                                           #cc_c;
flush_mapped_buffer_range:              proc(target: u32, offset: int, length: int)                                                                                  #cc_c;
bind_vertex_array:                     proc(array: u32)                                                                                                             #cc_c;
delete_vertex_arrays:                  proc(n: i32, arrays: ^u32)                                                                                                   #cc_c;
gen_vertex_arrays:                     proc(n: i32, arrays: ^u32)                                                                                                   #cc_c;
is_vertex_array:                       proc(array: u32) -> u8                                                                                                       #cc_c;

load_3_0 :: proc() {
	_set_proc_address(&color_mask_i,                          "glColorMaski\x00");
	_set_proc_address(&get_boolean_i_v,                       "glGetBooleani_v\x00");
	_set_proc_address(&get_integer_i_v,                       "glGetIntegeri_v\x00");
	_set_proc_address(&enable_i,                             "glEnablei\x00");
	_set_proc_address(&disable_i,                            "glDisablei\x00");
	_set_proc_address(&is_enabled_i,                          "glIsEnabledi\x00");
	_set_proc_address(&begin_transform_feedback,              "glBeginTransformFeedback\x00");
	_set_proc_address(&end_transform_feedback,                "glEndTransformFeedback\x00");
	_set_proc_address(&bind_buffer_range,                     "glBindBufferRange\x00");
	_set_proc_address(&bind_buffer_base,                      "glBindBufferBase\x00");
	_set_proc_address(&transform_feedback_varyings,           "glTransformFeedbackVaryings\x00");
	_set_proc_address(&get_transform_feedback_varying,         "glGetTransformFeedbackVarying\x00");
	_set_proc_address(&clamp_color,                          "glClampColor\x00");
	_set_proc_address(&begin_conditional_render,              "glBeginConditionalRender\x00");
	_set_proc_address(&end_conditional_render,                "glEndConditionalRender\x00");
	_set_proc_address(&vertex_attrib_i_pointer,                "glVertexAttribIPointer\x00");
	_set_proc_address(&get_vertex_attrib_iiv,                  "glGetVertexAttribIiv\x00");
	_set_proc_address(&get_vertex_attrib_iuiv,                 "glGetVertexAttribIuiv\x00");
	_set_proc_address(&vertex_attrib_i1i,                     "glVertexAttribI1i\x00");
	_set_proc_address(&vertex_attrib_i2i,                     "glVertexAttribI2i\x00");
	_set_proc_address(&vertex_attrib_i3i,                     "glVertexAttribI3i\x00");
	_set_proc_address(&vertex_attrib_i4i,                     "glVertexAttribI4i\x00");
	_set_proc_address(&vertex_attrib_i1ui,                    "glVertexAttribI1ui\x00");
	_set_proc_address(&vertex_attrib_i2ui,                    "glVertexAttribI2ui\x00");
	_set_proc_address(&vertex_attrib_i3ui,                    "glVertexAttribI3ui\x00");
	_set_proc_address(&vertex_attrib_i4ui,                    "glVertexAttribI4ui\x00");
	_set_proc_address(&vertex_attrib_i1iv,                    "glVertexAttribI1iv\x00");
	_set_proc_address(&vertex_attrib_i2iv,                    "glVertexAttribI2iv\x00");
	_set_proc_address(&vertex_attrib_i3iv,                    "glVertexAttribI3iv\x00");
	_set_proc_address(&vertex_attrib_i4iv,                    "glVertexAttribI4iv\x00");
	_set_proc_address(&vertex_attrib_i1uiv,                   "glVertexAttribI1uiv\x00");
	_set_proc_address(&vertex_attrib_i2uiv,                   "glVertexAttribI2uiv\x00");
	_set_proc_address(&vertex_attrib_i3uiv,                   "glVertexAttribI3uiv\x00");
	_set_proc_address(&vertex_attrib_i4uiv,                   "glVertexAttribI4uiv\x00");
	_set_proc_address(&vertex_attrib_i4bv,                    "glVertexAttribI4bv\x00");
	_set_proc_address(&vertex_attrib_i4sv,                    "glVertexAttribI4sv\x00");
	_set_proc_address(&vertex_attrib_i4ubv,                   "glVertexAttribI4ubv\x00");
	_set_proc_address(&vertex_attrib_i4usv,                   "glVertexAttribI4usv\x00");
	_set_proc_address(&get_uniform_uiv,                       "glGetUniformuiv\x00");
	_set_proc_address(&bind_frag_data_location,                "glBindFragDataLocation\x00");
	_set_proc_address(&get_frag_data_location,                 "glGetFragDataLocation\x00");
	_set_proc_address(&uniform_1ui,                          "glUniform1ui\x00");
	_set_proc_address(&uniform_2ui,                          "glUniform2ui\x00");
	_set_proc_address(&uniform_3ui,                          "glUniform3ui\x00");
	_set_proc_address(&uniform_4ui,                          "glUniform4ui\x00");
	_set_proc_address(&uniform_1uiv,                         "glUniform1uiv\x00");
	_set_proc_address(&uniform_2uiv,                         "glUniform2uiv\x00");
	_set_proc_address(&uniform_3uiv,                         "glUniform3uiv\x00");
	_set_proc_address(&uniform_4uiv,                         "glUniform4uiv\x00");
	_set_proc_address(&tex_parameter_iiv,                     "glTexParameterIiv\x00");
	_set_proc_address(&tex_parameter_iuiv,                    "glTexParameterIuiv\x00");
	_set_proc_address(&get_tex_parameter_iiv,                  "glGetTexParameterIiv\x00");
	_set_proc_address(&get_tex_parameter_iuiv,                 "glGetTexParameterIuiv\x00");
	_set_proc_address(&clear_buffer_iv,                       "glClearBufferiv\x00");
	_set_proc_address(&clear_buffer_uiv,                      "glClearBufferuiv\x00");
	_set_proc_address(&clear_buffer_fv,                       "glClearBufferfv\x00");
	_set_proc_address(&clear_bufferfi,                       "glClearBufferfi\x00");
	_set_proc_address(&get_string_i,                          "glGetStringi\x00");
	_set_proc_address(&is_renderbuffer,                      "glIsRenderbuffer\x00");
	_set_proc_address(&bind_renderbuffer,                    "glBindRenderbuffer\x00");
	_set_proc_address(&delete_renderbuffers,                 "glDeleteRenderbuffers\x00");
	_set_proc_address(&gen_renderbuffers,                    "glGenRenderbuffers\x00");
	_set_proc_address(&renderbuffer_storage,                 "glRenderbufferStorage\x00");
	_set_proc_address(&get_renderbuffer_parameter_iv,          "glGetRenderbufferParameteriv\x00");
	_set_proc_address(&is_framebuffer,                       "glIsFramebuffer\x00");
	_set_proc_address(&bind_framebuffer,                     "glBindFramebuffer\x00");
	_set_proc_address(&delete_framebuffers,                  "glDeleteFramebuffers\x00");
	_set_proc_address(&gen_framebuffers,                     "glGenFramebuffers\x00");
	_set_proc_address(&check_framebuffer_status,              "glCheckFramebufferStatus\x00");
	_set_proc_address(&framebuffer_texture_1d,                "glFramebufferTexture1D\x00");
	_set_proc_address(&framebuffer_texture_2d,                "glFramebufferTexture2D\x00");
	_set_proc_address(&framebuffer_texture_3d,                "glFramebufferTexture3D\x00");
	_set_proc_address(&framebuffer_renderbuffer,             "glFramebufferRenderbuffer\x00");
	_set_proc_address(&get_framebuffer_attachment_parameter_iv, "glGetFramebufferAttachmentParameteriv\x00");
	_set_proc_address(&generate_mipmap,                      "glGenerateMipmap\x00");
	_set_proc_address(&blit_framebuffer,                     "glBlitFramebuffer\x00");
	_set_proc_address(&renderbuffer_storage_multisample,      "glRenderbufferStorageMultisample\x00");
	_set_proc_address(&framebuffer_texture_layer,             "glFramebufferTextureLayer\x00");
	_set_proc_address(&map_buffer_range,                      "glMapBufferRange\x00");
	_set_proc_address(&flush_mapped_buffer_range,              "glFlushMappedBufferRange\x00");
	_set_proc_address(&bind_vertex_array,                     "glBindVertexArray\x00");
	_set_proc_address(&delete_vertex_arrays,                  "glDeleteVertexArrays\x00");
	_set_proc_address(&gen_vertex_arrays,                     "glGenVertexArrays\x00");
	_set_proc_address(&is_vertex_array,                       "glIsVertexArray\x00");
}


// VERSION_3_1
draw_arrays_instanced:       proc(mode: u32, first: i32, count: i32, instancecount: i32)                                   #cc_c;
draw_elements_instanced:     proc(mode: u32, count: i32, type_: u32, indices: rawptr, instancecount: i32)                  #cc_c;
tex_buffer:                 proc(target: u32, internalformat: u32, buffer: u32)                                           #cc_c;
primitive_restart_index:     proc(index: u32)                                                                              #cc_c;
copy_buffer_sub_data:         proc(readTarget: u32, writeTarget: u32, readOffset: int, writeOffset: int, size: int)         #cc_c;
get_uniform_indices:         proc(program: u32, uniformCount: i32, uniformNames: ^u8, uniformIndices: ^u32)                #cc_c;
get_active_uniforms_iv:       proc(program: u32, uniformCount: i32, uniformIndices: ^u32, pname: u32, params: ^i32)         #cc_c;
get_active_uniform_name:      proc(program: u32, uniformIndex: u32, bufSize: i32, length: ^i32, uniformName: ^u8)           #cc_c;
get_uniform_block_index:      proc(program: u32, uniformBlockName: ^u8) -> u32                                              #cc_c;
get_active_uniform_block_iv:   proc(program: u32, uniformBlockIndex: u32, pname: u32, params: ^i32)                          #cc_c;
get_active_uniform_block_name: proc(program: u32, uniformBlockIndex: u32, bufSize: i32, length: ^i32, uniformBlockName: ^u8) #cc_c;
uniform_block_binding:       proc(program: u32, uniformBlockIndex: u32, uniformBlockBinding: u32)                          #cc_c;

load_3_1 :: proc() {
	_set_proc_address(&draw_arrays_instanced,       "glDrawArraysInstanced\x00");
	_set_proc_address(&draw_elements_instanced,     "glDrawElementsInstanced\x00");
	_set_proc_address(&tex_buffer,                 "glTexBuffer\x00");
	_set_proc_address(&primitive_restart_index,     "glPrimitiveRestartIndex\x00");
	_set_proc_address(&copy_buffer_sub_data,         "glCopyBufferSubData\x00");
	_set_proc_address(&get_uniform_indices,         "glGetUniformIndices\x00");
	_set_proc_address(&get_active_uniforms_iv,       "glGetActiveUniformsiv\x00");
	_set_proc_address(&get_active_uniform_name,      "glGetActiveUniformName\x00");
	_set_proc_address(&get_uniform_block_index,      "glGetUniformBlockIndex\x00");
	_set_proc_address(&get_active_uniform_block_iv,   "glGetActiveUniformBlockiv\x00");
	_set_proc_address(&get_active_uniform_block_name, "glGetActiveUniformBlockName\x00");
	_set_proc_address(&uniform_block_binding,       "glUniformBlockBinding\x00");
}


// VERSION_3_2
draw_elements_base_vertex:          proc(mode: u32, count: i32, type_: u32, indices: rawptr, basevertex: i32)                                           #cc_c;
draw_range_elements_base_vertex:     proc(mode: u32, start: u32, end: u32, count: i32, type_: u32, indices: rawptr, basevertex: i32)                     #cc_c;
draw_elements_instanced_base_vertex: proc(mode: u32, count: i32, type_: u32, indices: rawptr, instancecount: i32, basevertex: i32)                       #cc_c;
multi_draw_elements_base_vertex:     proc(mode: u32, count: ^i32, type_: u32, indices: ^rawptr, drawcount: i32, basevertex: ^i32)                        #cc_c;
provoking_vertex:                 proc(mode: u32)                                                                                                     #cc_c;
fence_sync:                       proc(condition: u32, flags: u32) -> sync_t                                                                          #cc_c;
is_sync:                          proc(sync: sync_t) -> u8                                                                                            #cc_c;
delete_sync:                      proc(sync: sync_t)                                                                                                  #cc_c;
client_wait_sync:                  proc(sync: sync_t, flags: u32, timeout: u64) -> u32                                                                 #cc_c;
wait_sync:                        proc(sync: sync_t, flags: u32, timeout: u64)                                                                        #cc_c;
get_integer64_v:                   proc(pname: u32, data: ^i64)                                                                                        #cc_c;
get_sync_iv:                       proc(sync: sync_t, pname: u32, bufSize: i32, length: ^i32, values: ^i32)                                            #cc_c;
get_integer64i_v:                 proc(target: u32, index: u32, data: ^i64)                                                                           #cc_c;
get_buffer_parameter_i64v:          proc(target: u32, pname: u32, params: ^i64)                                                                         #cc_c;
framebuffer_texture:              proc(target: u32, attachment: u32, texture: u32, level: i32)                                                        #cc_c;
tex_image_2d_multisample:           proc(target: u32, samples: i32, internalformat: u32, width: i32, height: i32, fixedsamplelocations: u8)             #cc_c;
tex_image_3d_multisample:           proc(target: u32, samples: i32, internalformat: u32, width: i32, height: i32, depth: i32, fixedsamplelocations: u8) #cc_c;
get_multisample_fv:                proc(pname: u32, index: u32, val: ^f32)                                                                             #cc_c;
sample_mask_i:                     proc(maskNumber: u32, mask: u32)                                                                                    #cc_c;

load_3_2 :: proc() {
	_set_proc_address(&draw_elements_base_vertex,          "glDrawElementsBaseVertex\x00");
	_set_proc_address(&draw_range_elements_base_vertex,     "glDrawRangeElementsBaseVertex\x00");
	_set_proc_address(&draw_elements_instanced_base_vertex, "glDrawElementsInstancedBaseVertex\x00");
	_set_proc_address(&multi_draw_elements_base_vertex,     "glMultiDrawElementsBaseVertex\x00");
	_set_proc_address(&provoking_vertex,                 "glProvokingVertex\x00");
	_set_proc_address(&fence_sync,                       "glFenceSync\x00");
	_set_proc_address(&is_sync,                          "glIsSync\x00");
	_set_proc_address(&delete_sync,                      "glDeleteSync\x00");
	_set_proc_address(&client_wait_sync,                  "glClientWaitSync\x00");
	_set_proc_address(&wait_sync,                        "glWaitSync\x00");
	_set_proc_address(&get_integer64_v,                   "glGetInteger64v\x00");
	_set_proc_address(&get_sync_iv,                       "glGetSynciv\x00");
	_set_proc_address(&get_integer64i_v,                 "glGetInteger64i_v\x00");
	_set_proc_address(&get_buffer_parameter_i64v,          "glGetBufferParameteri64v\x00");
	_set_proc_address(&framebuffer_texture,              "glFramebufferTexture\x00");
	_set_proc_address(&tex_image_2d_multisample,           "glTexImage2DMultisample\x00");
	_set_proc_address(&tex_image_3d_multisample,           "glTexImage3DMultisample\x00");
	_set_proc_address(&get_multisample_fv,                "glGetMultisamplefv\x00");
	_set_proc_address(&sample_mask_i,                     "glSampleMaski\x00");
}


// VERSION_3_3
bind_frag_data_location_indexed: proc(program: u32, colorNumber: u32, index: u32, name: ^u8) #cc_c;
get_frag_data_index:            proc(program: u32, name: ^u8) -> i32                        #cc_c;
gen_samplers:                 proc(count: i32, samplers: ^u32)                            #cc_c;
delete_samplers:              proc(count: i32, samplers: ^u32)                            #cc_c;
is_sampler:                   proc(sampler: u32) -> u8                                    #cc_c;
bind_sampler:                 proc(unit: u32, sampler: u32)                               #cc_c;
sampler_parameter_i:           proc(sampler: u32, pname: u32, param: i32)                  #cc_c;
sampler_parameter_iv:          proc(sampler: u32, pname: u32, param: ^i32)                 #cc_c;
sampler_parameter_f:           proc(sampler: u32, pname: u32, param: f32)                  #cc_c;
sampler_parameter_fv:          proc(sampler: u32, pname: u32, param: ^f32)                 #cc_c;
sampler_parameter_iiv:         proc(sampler: u32, pname: u32, param: ^i32)                 #cc_c;
sampler_parameter_iuiv:        proc(sampler: u32, pname: u32, param: ^u32)                 #cc_c;
get_sampler_parameter_iv:       proc(sampler: u32, pname: u32, params: ^i32)                #cc_c;
get_sampler_parameter_iiv:      proc(sampler: u32, pname: u32, params: ^i32)                #cc_c;
get_sampler_parameter_fv:       proc(sampler: u32, pname: u32, params: ^f32)                #cc_c;
get_sampler_parameter_iuiv:     proc(sampler: u32, pname: u32, params: ^u32)                #cc_c;
query_counter:                proc(id: u32, target: u32)                                  #cc_c;
get_query_object_i64v:          proc(id: u32, pname: u32, params: ^i64)                     #cc_c;
get_query_object_ui64v:         proc(id: u32, pname: u32, params: ^u64)                     #cc_c;
vertex_attrib_divisor:         proc(index: u32, divisor: u32)                              #cc_c;
vertex_attrib_p1ui:            proc(index: u32, type_: u32, normalized: u8, value: u32)    #cc_c;
vertex_attrib_p1uiv:           proc(index: u32, type_: u32, normalized: u8, value: ^u32)   #cc_c;
vertex_attrib_p2ui:            proc(index: u32, type_: u32, normalized: u8, value: u32)    #cc_c;
vertex_attrib_p2uiv:           proc(index: u32, type_: u32, normalized: u8, value: ^u32)   #cc_c;
vertex_attrib_p3ui:            proc(index: u32, type_: u32, normalized: u8, value: u32)    #cc_c;
vertex_attrib_p3uiv:           proc(index: u32, type_: u32, normalized: u8, value: ^u32)   #cc_c;
vertex_attrib_p4ui:            proc(index: u32, type_: u32, normalized: u8, value: u32)    #cc_c;
vertex_attrib_p4uiv:           proc(index: u32, type_: u32, normalized: u8, value: ^u32)   #cc_c;
vertex_p2ui:                  proc(type_: u32, value: u32)                                #cc_c;
vertex_p2uiv:                 proc(type_: u32, value: ^u32)                               #cc_c;
vertex_p3ui:                  proc(type_: u32, value: u32)                                #cc_c;
vertex_p3uiv:                 proc(type_: u32, value: ^u32)                               #cc_c;
vertex_p4ui:                  proc(type_: u32, value: u32)                                #cc_c;
vertex_p4uiv:                 proc(type_: u32, value: ^u32)                               #cc_c;
tex_coord_p1ui:                proc(type_: u32, coords: u32)                               #cc_c;
tex_coord_p1uiv:               proc(type_: u32, coords: ^u32)                              #cc_c;
tex_coord_p2ui:                proc(type_: u32, coords: u32)                               #cc_c;
tex_coord_p2uiv:               proc(type_: u32, coords: ^u32)                              #cc_c;
tex_coord_p3ui:                proc(type_: u32, coords: u32)                               #cc_c;
tex_coord_p3uiv:               proc(type_: u32, coords: ^u32)                              #cc_c;
tex_coord_p4ui:                proc(type_: u32, coords: u32)                               #cc_c;
tex_coord_p4uiv:               proc(type_: u32, coords: ^u32)                              #cc_c;
multi_tex_coord_p1ui:           proc(texture: u32, type_: u32, coords: u32)                 #cc_c;
multi_tex_coord_p1uiv:          proc(texture: u32, type_: u32, coords: ^u32)                #cc_c;
multi_tex_coord_p2ui:           proc(texture: u32, type_: u32, coords: u32)                 #cc_c;
multi_tex_coord_p2uiv:          proc(texture: u32, type_: u32, coords: ^u32)                #cc_c;
multi_tex_coord_p3ui:           proc(texture: u32, type_: u32, coords: u32)                 #cc_c;
multi_tex_coord_p3uiv:          proc(texture: u32, type_: u32, coords: ^u32)                #cc_c;
multi_tex_coord_p4ui:           proc(texture: u32, type_: u32, coords: u32)                 #cc_c;
multi_tex_coord_p4uiv:          proc(texture: u32, type_: u32, coords: ^u32)                #cc_c;
normal_p3ui:                  proc(type_: u32, coords: u32)                               #cc_c;
normal_p3uiv:                 proc(type_: u32, coords: ^u32)                              #cc_c;
color_p3ui:                   proc(type_: u32, color: u32)                                #cc_c;
color_p3uiv:                  proc(type_: u32, color: ^u32)                               #cc_c;
color_p4ui:                   proc(type_: u32, color: u32)                                #cc_c;
color_p4uiv:                  proc(type_: u32, color: ^u32)                               #cc_c;
secondary_color_p3ui:          proc(type_: u32, color: u32)                                #cc_c;
secondary_color_p3uiv:         proc(type_: u32, color: ^u32)                               #cc_c;

load_3_3 :: proc() {
	_set_proc_address(&bind_frag_data_location_indexed, "glBindFragDataLocationIndexed\x00");
	_set_proc_address(&get_frag_data_index,            "glGetFragDataIndex\x00");
	_set_proc_address(&gen_samplers,                 "glGenSamplers\x00");
	_set_proc_address(&delete_samplers,              "glDeleteSamplers\x00");
	_set_proc_address(&is_sampler,                   "glIsSampler\x00");
	_set_proc_address(&bind_sampler,                 "glBindSampler\x00");
	_set_proc_address(&sampler_parameter_i,           "glSamplerParameteri\x00");
	_set_proc_address(&sampler_parameter_iv,          "glSamplerParameteriv\x00");
	_set_proc_address(&sampler_parameter_f,           "glSamplerParameterf\x00");
	_set_proc_address(&sampler_parameter_fv,          "glSamplerParameterfv\x00");
	_set_proc_address(&sampler_parameter_iiv,         "glSamplerParameterIiv\x00");
	_set_proc_address(&sampler_parameter_iuiv,        "glSamplerParameterIuiv\x00");
	_set_proc_address(&get_sampler_parameter_iv,       "glGetSamplerParameteriv\x00");
	_set_proc_address(&get_sampler_parameter_iiv,      "glGetSamplerParameterIiv\x00");
	_set_proc_address(&get_sampler_parameter_fv,       "glGetSamplerParameterfv\x00");
	_set_proc_address(&get_sampler_parameter_iuiv,     "glGetSamplerParameterIuiv\x00");
	_set_proc_address(&query_counter,                "glQueryCounter\x00");
	_set_proc_address(&get_query_object_i64v,          "glGetQueryObjecti64v\x00");
	_set_proc_address(&get_query_object_ui64v,         "glGetQueryObjectui64v\x00");
	_set_proc_address(&vertex_attrib_divisor,         "glVertexAttribDivisor\x00");
	_set_proc_address(&vertex_attrib_p1ui,            "glVertexAttribP1ui\x00");
	_set_proc_address(&vertex_attrib_p1uiv,           "glVertexAttribP1uiv\x00");
	_set_proc_address(&vertex_attrib_p2ui,            "glVertexAttribP2ui\x00");
	_set_proc_address(&vertex_attrib_p2uiv,           "glVertexAttribP2uiv\x00");
	_set_proc_address(&vertex_attrib_p3ui,            "glVertexAttribP3ui\x00");
	_set_proc_address(&vertex_attrib_p3uiv,           "glVertexAttribP3uiv\x00");
	_set_proc_address(&vertex_attrib_p4ui,            "glVertexAttribP4ui\x00");
	_set_proc_address(&vertex_attrib_p4uiv,           "glVertexAttribP4uiv\x00");
	_set_proc_address(&vertex_p2ui,                  "glVertexP2ui\x00");
	_set_proc_address(&vertex_p2uiv,                 "glVertexP2uiv\x00");
	_set_proc_address(&vertex_p3ui,                  "glVertexP3ui\x00");
	_set_proc_address(&vertex_p3uiv,                 "glVertexP3uiv\x00");
	_set_proc_address(&vertex_p4ui,                  "glVertexP4ui\x00");
	_set_proc_address(&vertex_p4uiv,                 "glVertexP4uiv\x00");
	_set_proc_address(&tex_coord_p1ui,                "glTexCoordP1ui\x00");
	_set_proc_address(&tex_coord_p1uiv,               "glTexCoordP1uiv\x00");
	_set_proc_address(&tex_coord_p2ui,                "glTexCoordP2ui\x00");
	_set_proc_address(&tex_coord_p2uiv,               "glTexCoordP2uiv\x00");
	_set_proc_address(&tex_coord_p3ui,                "glTexCoordP3ui\x00");
	_set_proc_address(&tex_coord_p3uiv,               "glTexCoordP3uiv\x00");
	_set_proc_address(&tex_coord_p4ui,                "glTexCoordP4ui\x00");
	_set_proc_address(&tex_coord_p4uiv,               "glTexCoordP4uiv\x00");
	_set_proc_address(&multi_tex_coord_p1ui,           "glMultiTexCoordP1ui\x00");
	_set_proc_address(&multi_tex_coord_p1uiv,          "glMultiTexCoordP1uiv\x00");
	_set_proc_address(&multi_tex_coord_p2ui,           "glMultiTexCoordP2ui\x00");
	_set_proc_address(&multi_tex_coord_p2uiv,          "glMultiTexCoordP2uiv\x00");
	_set_proc_address(&multi_tex_coord_p3ui,           "glMultiTexCoordP3ui\x00");
	_set_proc_address(&multi_tex_coord_p3uiv,          "glMultiTexCoordP3uiv\x00");
	_set_proc_address(&multi_tex_coord_p4ui,           "glMultiTexCoordP4ui\x00");
	_set_proc_address(&multi_tex_coord_p4uiv,          "glMultiTexCoordP4uiv\x00");
	_set_proc_address(&normal_p3ui,                  "glNormalP3ui\x00");
	_set_proc_address(&normal_p3uiv,                 "glNormalP3uiv\x00");
	_set_proc_address(&color_p3ui,                   "glColorP3ui\x00");
	_set_proc_address(&color_p3uiv,                  "glColorP3uiv\x00");
	_set_proc_address(&color_p4ui,                   "glColorP4ui\x00");
	_set_proc_address(&color_p4uiv,                  "glColorP4uiv\x00");
	_set_proc_address(&secondary_color_p3ui,          "glSecondaryColorP3ui\x00");
	_set_proc_address(&secondary_color_p3uiv,         "glSecondaryColorP3uiv\x00");
}


// VERSION_4_0
min_sample_shading:               proc(value: f32)                                                                        #cc_c;
blend_equation_i:                 proc(buf: u32, mode: u32)                                                               #cc_c;
blend_equation_separate_i:         proc(buf: u32, modeRGB: u32, modeAlpha: u32)                                            #cc_c;
blend_func_i:                     proc(buf: u32, src: u32, dst: u32)                                                      #cc_c;
blend_func_separate_i:             proc(buf: u32, srcRGB: u32, dstRGB: u32, srcAlpha: u32, dstAlpha: u32)                  #cc_c;
draw_arrays_indirect:             proc(mode: u32, indirect: rawptr)                                                       #cc_c;
draw_elements_indirect:           proc(mode: u32, type_: u32, indirect: rawptr)                                           #cc_c;
uniform_1d:                      proc(location: i32, x: f64)                                                             #cc_c;
uniform_2d:                      proc(location: i32, x: f64, y: f64)                                                     #cc_c;
uniform_3d:                      proc(location: i32, x: f64, y: f64, z: f64)                                             #cc_c;
uniform_4d:                      proc(location: i32, x: f64, y: f64, z: f64, w: f64)                                     #cc_c;
uniform_1dv:                     proc(location: i32, count: i32, value: ^f64)                                            #cc_c;
uniform_2dv:                     proc(location: i32, count: i32, value: ^f64)                                            #cc_c;
uniform_3dv:                     proc(location: i32, count: i32, value: ^f64)                                            #cc_c;
uniform_4dv:                     proc(location: i32, count: i32, value: ^f64)                                            #cc_c;
uniform_matrix_2dv:               proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_3dv:               proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_4dv:               proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_2x3dv:             proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_2x4dv:             proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_3x2dv:             proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_3x4dv:             proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_4x2dv:             proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
uniform_matrix_4x3dv:             proc(location: i32, count: i32, transpose: u8, value: ^f64)                             #cc_c;
get_uniform_dv:                   proc(program: u32, location: i32, params: ^f64)                                         #cc_c;
get_subroutine_uniform_location:   proc(program: u32, shadertype_: u32, name: ^u8) -> i32                                  #cc_c;
get_subroutine_index:             proc(program: u32, shadertype_: u32, name: ^u8) -> u32                                  #cc_c;
get_active_subroutine_uniform_iv:   proc(program: u32, shadertype_: u32, index: u32, pname: u32, values: ^i32)              #cc_c;
get_active_subroutine_uniform_name: proc(program: u32, shadertype_: u32, index: u32, bufsize: i32, length: ^i32, name: ^u8) #cc_c;
get_active_subroutine_name:        proc(program: u32, shadertype_: u32, index: u32, bufsize: i32, length: ^i32, name: ^u8) #cc_c;
uniform_subroutines_uiv:          proc(shadertype_: u32, count: i32, indices: ^u32)                                       #cc_c;
get_uniform_subroutine_uiv:        proc(shadertype_: u32, location: i32, params: ^u32)                                     #cc_c;
get_program_stage_iv:              proc(program: u32, shadertype_: u32, pname: u32, values: ^i32)                          #cc_c;
patch_parameter_i:                proc(pname: u32, value: i32)                                                            #cc_c;
patch_parameter_fv:               proc(pname: u32, values: ^f32)                                                          #cc_c;
bind_transform_feedback:          proc(target: u32, id: u32)                                                              #cc_c;
delete_transform_feedbacks:       proc(n: i32, ids: ^u32)                                                                 #cc_c;
gen_transform_feedbacks:          proc(n: i32, ids: ^u32)                                                                 #cc_c;
is_transform_feedback:            proc(id: u32) -> u8                                                                     #cc_c;
pause_transform_feedback:         proc()                                                                                  #cc_c;
resume_transform_feedback:        proc()                                                                                  #cc_c;
draw_transform_feedback:          proc(mode: u32, id: u32)                                                                #cc_c;
draw_transform_feedback_stream:    proc(mode: u32, id: u32, stream: u32)                                                   #cc_c;
begin_query_indexed:              proc(target: u32, index: u32, id: u32)                                                  #cc_c;
end_query_indexed:                proc(target: u32, index: u32)                                                           #cc_c;
get_query_indexed_iv:              proc(target: u32, index: u32, pname: u32, params: ^i32)                                 #cc_c;

load_4_0 :: proc() {
	_set_proc_address(&min_sample_shading,               "glMinSampleShading\x00");
	_set_proc_address(&blend_equation_i,                 "glBlendEquationi\x00");
	_set_proc_address(&blend_equation_separate_i,         "glBlendEquationSeparatei\x00");
	_set_proc_address(&blend_func_i,                     "glBlendFunci\x00");
	_set_proc_address(&blend_func_separate_i,             "glBlendFuncSeparatei\x00");
	_set_proc_address(&draw_arrays_indirect,             "glDrawArraysIndirect\x00");
	_set_proc_address(&draw_elements_indirect,           "glDrawElementsIndirect\x00");
	_set_proc_address(&uniform_1d,                      "glUniform1d\x00");
	_set_proc_address(&uniform_2d,                      "glUniform2d\x00");
	_set_proc_address(&uniform_3d,                      "glUniform3d\x00");
	_set_proc_address(&uniform_4d,                      "glUniform4d\x00");
	_set_proc_address(&uniform_1dv,                     "glUniform1dv\x00");
	_set_proc_address(&uniform_2dv,                     "glUniform2dv\x00");
	_set_proc_address(&uniform_3dv,                     "glUniform3dv\x00");
	_set_proc_address(&uniform_4dv,                     "glUniform4dv\x00");
	_set_proc_address(&uniform_matrix_2dv,               "glUniformMatrix2dv\x00");
	_set_proc_address(&uniform_matrix_3dv,               "glUniformMatrix3dv\x00");
	_set_proc_address(&uniform_matrix_4dv,               "glUniformMatrix4dv\x00");
	_set_proc_address(&uniform_matrix_2x3dv,             "glUniformMatrix2x3dv\x00");
	_set_proc_address(&uniform_matrix_2x4dv,             "glUniformMatrix2x4dv\x00");
	_set_proc_address(&uniform_matrix_3x2dv,             "glUniformMatrix3x2dv\x00");
	_set_proc_address(&uniform_matrix_3x4dv,             "glUniformMatrix3x4dv\x00");
	_set_proc_address(&uniform_matrix_4x2dv,             "glUniformMatrix4x2dv\x00");
	_set_proc_address(&uniform_matrix_4x3dv,             "glUniformMatrix4x3dv\x00");
	_set_proc_address(&get_uniform_dv,                   "glGetUniformdv\x00");
	_set_proc_address(&get_subroutine_uniform_location,   "glGetSubroutineUniformLocation\x00");
	_set_proc_address(&get_subroutine_index,             "glGetSubroutineIndex\x00");
	_set_proc_address(&get_active_subroutine_uniform_iv,   "glGetActiveSubroutineUniformiv\x00");
	_set_proc_address(&get_active_subroutine_uniform_name, "glGetActiveSubroutineUniformName\x00");
	_set_proc_address(&get_active_subroutine_name,        "glGetActiveSubroutineName\x00");
	_set_proc_address(&uniform_subroutines_uiv,          "glUniformSubroutinesuiv\x00");
	_set_proc_address(&get_uniform_subroutine_uiv,        "glGetUniformSubroutineuiv\x00");
	_set_proc_address(&get_program_stage_iv,              "glGetProgramStageiv\x00");
	_set_proc_address(&patch_parameter_i,                "glPatchParameteri\x00");
	_set_proc_address(&patch_parameter_fv,               "glPatchParameterfv\x00");
	_set_proc_address(&bind_transform_feedback,          "glBindTransformFeedback\x00");
	_set_proc_address(&delete_transform_feedbacks,       "glDeleteTransformFeedbacks\x00");
	_set_proc_address(&gen_transform_feedbacks,          "glGenTransformFeedbacks\x00");
	_set_proc_address(&is_transform_feedback,            "glIsTransformFeedback\x00");
	_set_proc_address(&pause_transform_feedback,         "glPauseTransformFeedback\x00");
	_set_proc_address(&resume_transform_feedback,        "glResumeTransformFeedback\x00");
	_set_proc_address(&draw_transform_feedback,          "glDrawTransformFeedback\x00");
	_set_proc_address(&draw_transform_feedback_stream,    "glDrawTransformFeedbackStream\x00");
	_set_proc_address(&begin_query_indexed,              "glBeginQueryIndexed\x00");
	_set_proc_address(&end_query_indexed,                "glEndQueryIndexed\x00");
	_set_proc_address(&get_query_indexed_iv,              "glGetQueryIndexediv\x00");
}


// VERSION_4_1
release_shader_compiler:     proc()                                                                             #cc_c;
shader_binary:              proc(count: i32, shaders: ^u32, binaryformat: u32, binary: rawptr, length: i32)    #cc_c;
get_shader_precision_format:  proc(shadertype_: u32, precisiontype_: u32, range: ^i32, precision: ^i32)          #cc_c;
depth_range_f:               proc(n: f32, f: f32)                                                               #cc_c;
clear_depth_f:               proc(d: f32)                                                                       #cc_c;
get_program_binary:          proc(program: u32, bufSize: i32, length: ^i32, binaryFormat: ^u32, binary: rawptr) #cc_c;
program_binary:             proc(program: u32, binaryFormat: u32, binary: rawptr, length: i32)                 #cc_c;
program_parameter_i:         proc(program: u32, pname: u32, value: i32)                                         #cc_c;
use_program_stages:          proc(pipeline: u32, stages: u32, program: u32)                                     #cc_c;
active_shader_program:       proc(pipeline: u32, program: u32)                                                  #cc_c;
create_shader_program_v:      proc(type_: u32, count: i32, strings: ^u8) -> u32                                  #cc_c;
bind_program_pipeline:       proc(pipeline: u32)                                                                #cc_c;
delete_program_pipelines:    proc(n: i32, pipelines: ^u32)                                                      #cc_c;
gen_program_pipelines:       proc(n: i32, pipelines: ^u32)                                                      #cc_c;
is_program_pipeline:         proc(pipeline: u32) -> u8                                                          #cc_c;
get_program_pipeline_iv:      proc(pipeline: u32, pname: u32, params: ^i32)                                      #cc_c;
program_uniform_1i:          proc(program: u32, location: i32, v0: i32)                                         #cc_c;
program_uniform_1iv:         proc(program: u32, location: i32, count: i32, value: ^i32)                         #cc_c;
program_uniform_1f:          proc(program: u32, location: i32, v0: f32)                                         #cc_c;
program_uniform_1fv:         proc(program: u32, location: i32, count: i32, value: ^f32)                         #cc_c;
program_uniform_1d:          proc(program: u32, location: i32, v0: f64)                                         #cc_c;
program_uniform_1dv:         proc(program: u32, location: i32, count: i32, value: ^f64)                         #cc_c;
program_uniform_1ui:         proc(program: u32, location: i32, v0: u32)                                         #cc_c;
program_uniform_1uiv:        proc(program: u32, location: i32, count: i32, value: ^u32)                         #cc_c;
program_uniform_2i:          proc(program: u32, location: i32, v0: i32, v1: i32)                                #cc_c;
program_uniform_2iv:         proc(program: u32, location: i32, count: i32, value: ^i32)                         #cc_c;
program_uniform_2f:          proc(program: u32, location: i32, v0: f32, v1: f32)                                #cc_c;
program_uniform_2fv:         proc(program: u32, location: i32, count: i32, value: ^f32)                         #cc_c;
program_uniform_2d:          proc(program: u32, location: i32, v0: f64, v1: f64)                                #cc_c;
program_uniform_2dv:         proc(program: u32, location: i32, count: i32, value: ^f64)                         #cc_c;
program_uniform_2ui:         proc(program: u32, location: i32, v0: u32, v1: u32)                                #cc_c;
program_uniform_2uiv:        proc(program: u32, location: i32, count: i32, value: ^u32)                         #cc_c;
program_uniform_3i:          proc(program: u32, location: i32, v0: i32, v1: i32, v2: i32)                       #cc_c;
program_uniform_3iv:         proc(program: u32, location: i32, count: i32, value: ^i32)                         #cc_c;
program_uniform_3f:          proc(program: u32, location: i32, v0: f32, v1: f32, v2: f32)                       #cc_c;
program_uniform_3fv:         proc(program: u32, location: i32, count: i32, value: ^f32)                         #cc_c;
program_uniform_3d:          proc(program: u32, location: i32, v0: f64, v1: f64, v2: f64)                       #cc_c;
program_uniform_3dv:         proc(program: u32, location: i32, count: i32, value: ^f64)                         #cc_c;
program_uniform_3ui:         proc(program: u32, location: i32, v0: u32, v1: u32, v2: u32)                       #cc_c;
program_uniform_3uiv:        proc(program: u32, location: i32, count: i32, value: ^u32)                         #cc_c;
program_uniform_4i:          proc(program: u32, location: i32, v0: i32, v1: i32, v2: i32, v3: i32)              #cc_c;
program_uniform_4iv:         proc(program: u32, location: i32, count: i32, value: ^i32)                         #cc_c;
program_uniform_4f:          proc(program: u32, location: i32, v0: f32, v1: f32, v2: f32, v3: f32)              #cc_c;
program_uniform_4fv:         proc(program: u32, location: i32, count: i32, value: ^f32)                         #cc_c;
program_uniform_4d:          proc(program: u32, location: i32, v0: f64, v1: f64, v2: f64, v3: f64)              #cc_c;
program_uniform_4dv:         proc(program: u32, location: i32, count: i32, value: ^f64)                         #cc_c;
program_uniform_4ui:         proc(program: u32, location: i32, v0: u32, v1: u32, v2: u32, v3: u32)              #cc_c;
program_uniform_4uiv:        proc(program: u32, location: i32, count: i32, value: ^u32)                         #cc_c;
program_uniform_matrix2fv:   proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix3fv:   proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix4fv:   proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix2dv:   proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix3dv:   proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix4dv:   proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix2x3fv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix3x2fv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix2x4fv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix4x2fv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix3x4fv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix4x3fv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f32)          #cc_c;
program_uniform_matrix2x3dv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix3x2dv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix2x4dv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix4x2dv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix3x4dv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
program_uniform_matrix4x3dv: proc(program: u32, location: i32, count: i32, transpose: u8, value: ^f64)          #cc_c;
validate_program_pipeline:   proc(pipeline: u32)                                                                #cc_c;
get_program_pipeline_info_log: proc(pipeline: u32, bufSize: i32, length: ^i32, infoLog: ^u8)                      #cc_c;
vertex_attrib_l1d:           proc(index: u32, x: f64)                                                           #cc_c;
vertex_attrib_l2d:           proc(index: u32, x: f64, y: f64)                                                   #cc_c;
vertex_attrib_l3d:           proc(index: u32, x: f64, y: f64, z: f64)                                           #cc_c;
vertex_attrib_l4d:           proc(index: u32, x: f64, y: f64, z: f64, w: f64)                                   #cc_c;
vertex_attrib_l1dv:          proc(index: u32, v: ^f64)                                                          #cc_c;
vertex_attrib_l2dv:          proc(index: u32, v: ^f64)                                                          #cc_c;
vertex_attrib_l3dv:          proc(index: u32, v: ^f64)                                                          #cc_c;
vertex_attrib_l4dv:          proc(index: u32, v: ^f64)                                                          #cc_c;
vertex_attrib_l_pointer:      proc(index: u32, size: i32, type_: u32, stride: i32, pointer: rawptr)              #cc_c;
get_vertex_attrib_ldv:        proc(index: u32, pname: u32, params: ^f64)                                         #cc_c;
viewport_array_v:            proc(first: u32, count: i32, v: ^f32)                                              #cc_c;
viewport_indexed_f:          proc(index: u32, x: f32, y: f32, w: f32, h: f32)                                   #cc_c;
viewport_indexed_fv:         proc(index: u32, v: ^f32)                                                          #cc_c;
scissor_array_v:             proc(first: u32, count: i32, v: ^i32)                                              #cc_c;
scissor_indexed:            proc(index: u32, left: i32, bottom: i32, width: i32, height: i32)                  #cc_c;
scissor_indexed_v:           proc(index: u32, v: ^i32)                                                          #cc_c;
depth_range_array_v:          proc(first: u32, count: i32, v: ^f64)                                              #cc_c;
depth_range_indexed:         proc(index: u32, n: f64, f: f64)                                                   #cc_c;
get_floati_v:               proc(target: u32, index: u32, data: ^f32)                                          #cc_c;
get_doublei_v:              proc(target: u32, index: u32, data: ^f64)                                          #cc_c;

load_4_1 :: proc() {
	_set_proc_address(&release_shader_compiler,     "glReleaseShaderCompiler\x00");
	_set_proc_address(&shader_binary,              "glShaderBinary\x00");
	_set_proc_address(&get_shader_precision_format,  "glGetShaderPrecisionFormat\x00");
	_set_proc_address(&depth_range_f,               "glDepthRangef\x00");
	_set_proc_address(&clear_depth_f,               "glClearDepthf\x00");
	_set_proc_address(&get_program_binary,          "glGetProgramBinary\x00");
	_set_proc_address(&program_binary,             "glProgramBinary\x00");
	_set_proc_address(&program_parameter_i,         "glProgramParameteri\x00");
	_set_proc_address(&use_program_stages,          "glUseProgramStages\x00");
	_set_proc_address(&active_shader_program,       "glActiveShaderProgram\x00");
	_set_proc_address(&create_shader_program_v,      "glCreateShaderProgramv\x00");
	_set_proc_address(&bind_program_pipeline,       "glBindProgramPipeline\x00");
	_set_proc_address(&delete_program_pipelines,    "glDeleteProgramPipelines\x00");
	_set_proc_address(&gen_program_pipelines,       "glGenProgramPipelines\x00");
	_set_proc_address(&is_program_pipeline,         "glIsProgramPipeline\x00");
	_set_proc_address(&get_program_pipeline_iv,      "glGetProgramPipelineiv\x00");
	_set_proc_address(&program_uniform_1i,          "glProgramUniform1i\x00");
	_set_proc_address(&program_uniform_1iv,         "glProgramUniform1iv\x00");
	_set_proc_address(&program_uniform_1f,          "glProgramUniform1f\x00");
	_set_proc_address(&program_uniform_1fv,         "glProgramUniform1fv\x00");
	_set_proc_address(&program_uniform_1d,          "glProgramUniform1d\x00");
	_set_proc_address(&program_uniform_1dv,         "glProgramUniform1dv\x00");
	_set_proc_address(&program_uniform_1ui,         "glProgramUniform1ui\x00");
	_set_proc_address(&program_uniform_1uiv,        "glProgramUniform1uiv\x00");
	_set_proc_address(&program_uniform_2i,          "glProgramUniform2i\x00");
	_set_proc_address(&program_uniform_2iv,         "glProgramUniform2iv\x00");
	_set_proc_address(&program_uniform_2f,          "glProgramUniform2f\x00");
	_set_proc_address(&program_uniform_2fv,         "glProgramUniform2fv\x00");
	_set_proc_address(&program_uniform_2d,          "glProgramUniform2d\x00");
	_set_proc_address(&program_uniform_2dv,         "glProgramUniform2dv\x00");
	_set_proc_address(&program_uniform_2ui,         "glProgramUniform2ui\x00");
	_set_proc_address(&program_uniform_2uiv,        "glProgramUniform2uiv\x00");
	_set_proc_address(&program_uniform_3i,          "glProgramUniform3i\x00");
	_set_proc_address(&program_uniform_3iv,         "glProgramUniform3iv\x00");
	_set_proc_address(&program_uniform_3f,          "glProgramUniform3f\x00");
	_set_proc_address(&program_uniform_3fv,         "glProgramUniform3fv\x00");
	_set_proc_address(&program_uniform_3d,          "glProgramUniform3d\x00");
	_set_proc_address(&program_uniform_3dv,         "glProgramUniform3dv\x00");
	_set_proc_address(&program_uniform_3ui,         "glProgramUniform3ui\x00");
	_set_proc_address(&program_uniform_3uiv,        "glProgramUniform3uiv\x00");
	_set_proc_address(&program_uniform_4i,          "glProgramUniform4i\x00");
	_set_proc_address(&program_uniform_4iv,         "glProgramUniform4iv\x00");
	_set_proc_address(&program_uniform_4f,          "glProgramUniform4f\x00");
	_set_proc_address(&program_uniform_4fv,         "glProgramUniform4fv\x00");
	_set_proc_address(&program_uniform_4d,          "glProgramUniform4d\x00");
	_set_proc_address(&program_uniform_4dv,         "glProgramUniform4dv\x00");
	_set_proc_address(&program_uniform_4ui,         "glProgramUniform4ui\x00");
	_set_proc_address(&program_uniform_4uiv,        "glProgramUniform4uiv\x00");
	_set_proc_address(&program_uniform_matrix2fv,   "glProgramUniformMatrix2fv\x00");
	_set_proc_address(&program_uniform_matrix3fv,   "glProgramUniformMatrix3fv\x00");
	_set_proc_address(&program_uniform_matrix4fv,   "glProgramUniformMatrix4fv\x00");
	_set_proc_address(&program_uniform_matrix2dv,   "glProgramUniformMatrix2dv\x00");
	_set_proc_address(&program_uniform_matrix3dv,   "glProgramUniformMatrix3dv\x00");
	_set_proc_address(&program_uniform_matrix4dv,   "glProgramUniformMatrix4dv\x00");
	_set_proc_address(&program_uniform_matrix2x3fv, "glProgramUniformMatrix2x3fv\x00");
	_set_proc_address(&program_uniform_matrix3x2fv, "glProgramUniformMatrix3x2fv\x00");
	_set_proc_address(&program_uniform_matrix2x4fv, "glProgramUniformMatrix2x4fv\x00");
	_set_proc_address(&program_uniform_matrix4x2fv, "glProgramUniformMatrix4x2fv\x00");
	_set_proc_address(&program_uniform_matrix3x4fv, "glProgramUniformMatrix3x4fv\x00");
	_set_proc_address(&program_uniform_matrix4x3fv, "glProgramUniformMatrix4x3fv\x00");
	_set_proc_address(&program_uniform_matrix2x3dv, "glProgramUniformMatrix2x3dv\x00");
	_set_proc_address(&program_uniform_matrix3x2dv, "glProgramUniformMatrix3x2dv\x00");
	_set_proc_address(&program_uniform_matrix2x4dv, "glProgramUniformMatrix2x4dv\x00");
	_set_proc_address(&program_uniform_matrix4x2dv, "glProgramUniformMatrix4x2dv\x00");
	_set_proc_address(&program_uniform_matrix3x4dv, "glProgramUniformMatrix3x4dv\x00");
	_set_proc_address(&program_uniform_matrix4x3dv, "glProgramUniformMatrix4x3dv\x00");
	_set_proc_address(&validate_program_pipeline,   "glValidateProgramPipeline\x00");
	_set_proc_address(&get_program_pipeline_info_log, "glGetProgramPipelineInfoLog\x00");
	_set_proc_address(&vertex_attrib_l1d,           "glVertexAttribL1d\x00");
	_set_proc_address(&vertex_attrib_l2d,           "glVertexAttribL2d\x00");
	_set_proc_address(&vertex_attrib_l3d,           "glVertexAttribL3d\x00");
	_set_proc_address(&vertex_attrib_l4d,           "glVertexAttribL4d\x00");
	_set_proc_address(&vertex_attrib_l1dv,          "glVertexAttribL1dv\x00");
	_set_proc_address(&vertex_attrib_l2dv,          "glVertexAttribL2dv\x00");
	_set_proc_address(&vertex_attrib_l3dv,          "glVertexAttribL3dv\x00");
	_set_proc_address(&vertex_attrib_l4dv,          "glVertexAttribL4dv\x00");
	_set_proc_address(&vertex_attrib_l_pointer,      "glVertexAttribLPointer\x00");
	_set_proc_address(&get_vertex_attrib_ldv,        "glGetVertexAttribLdv\x00");
	_set_proc_address(&viewport_array_v,            "glViewportArrayv\x00");
	_set_proc_address(&viewport_indexed_f,          "glViewportIndexedf\x00");
	_set_proc_address(&viewport_indexed_fv,         "glViewportIndexedfv\x00");
	_set_proc_address(&scissor_array_v,             "glScissorArrayv\x00");
	_set_proc_address(&scissor_indexed,            "glScissorIndexed\x00");
	_set_proc_address(&scissor_indexed_v,           "glScissorIndexedv\x00");
	_set_proc_address(&depth_range_array_v,          "glDepthRangeArrayv\x00");
	_set_proc_address(&depth_range_indexed,         "glDepthRangeIndexed\x00");
	_set_proc_address(&get_floati_v,               "glGetFloati_v\x00");
	_set_proc_address(&get_doublei_v,              "glGetDoublei_v\x00");
}


// VERSION_4_2
draw_arrays_instanced_base_instance:             proc(mode: u32, first: i32, count: i32, instancecount: i32, baseinstance: u32)                                   #cc_c;
draw_elements_instanced_base_instance:           proc(mode: u32, count: i32, type_: u32, indices: rawptr, instancecount: i32, baseinstance: u32)                  #cc_c;
draw_elements_instanced_base_vertex_base_instance: proc(mode: u32, count: i32, type_: u32, indices: rawptr, instancecount: i32, basevertex: i32, baseinstance: u32) #cc_c;
get_internalformat_iv:                         proc(target: u32, internalformat: u32, pname: u32, bufSize: i32, params: ^i32)                                   #cc_c;
get_active_atomic_counter_buffer_iv:              proc(program: u32, bufferIndex: u32, pname: u32, params: ^i32)                                                   #cc_c;
bind_image_texture:                            proc(unit: u32, texture: u32, level: i32, layered: u8, layer: i32, access: u32, format: u32)                     #cc_c;
memory_barrier:                               proc(barriers: u32)                                                                                              #cc_c;
tex_storage_1d:                                proc(target: u32, levels: i32, internalformat: u32, width: i32)                                                  #cc_c;
tex_storage_2d:                                proc(target: u32, levels: i32, internalformat: u32, width: i32, height: i32)                                     #cc_c;
tex_storage_3d:                                proc(target: u32, levels: i32, internalformat: u32, width: i32, height: i32, depth: i32)                         #cc_c;
draw_transform_feedback_instanced:              proc(mode: u32, id: u32, instancecount: i32)                                                                     #cc_c;
draw_transform_feedback_stream_instanced:        proc(mode: u32, id: u32, stream: u32, instancecount: i32)                                                        #cc_c;

load_4_2 :: proc() {
	_set_proc_address(&draw_arrays_instanced_base_instance,             "glDrawArraysInstancedBaseInstance\x00");
	_set_proc_address(&draw_elements_instanced_base_instance,           "glDrawElementsInstancedBaseInstance\x00");
	_set_proc_address(&draw_elements_instanced_base_vertex_base_instance, "glDrawElementsInstancedBaseVertexBaseInstance\x00");
	_set_proc_address(&get_internalformat_iv,                         "glGetInternalformativ\x00");
	_set_proc_address(&get_active_atomic_counter_buffer_iv,              "glGetActiveAtomicCounterBufferiv\x00");
	_set_proc_address(&bind_image_texture,                            "glBindImageTexture\x00");
	_set_proc_address(&memory_barrier,                               "glMemoryBarrier\x00");
	_set_proc_address(&tex_storage_1d,                                "glTexStorage1D\x00");
	_set_proc_address(&tex_storage_2d,                                "glTexStorage2D\x00");
	_set_proc_address(&tex_storage_3d,                                "glTexStorage3D\x00");
	_set_proc_address(&draw_transform_feedback_instanced,              "glDrawTransformFeedbackInstanced\x00");
	_set_proc_address(&draw_transform_feedback_stream_instanced,        "glDrawTransformFeedbackStreamInstanced\x00");
}

// VERSION_4_3
clear_buffer_data:                 proc(target: u32, internalformat: u32, format: u32, type_: u32, data: rawptr)                                                                                                                                  #cc_c;
clear_buffer_sub_data:              proc(target: u32, internalformat: u32, offset: int, size: int, format: u32, type_: u32, data: rawptr)                                                                                                          #cc_c;
dispatch_compute:                 proc(num_groups_x: u32, num_groups_y: u32, num_groups_z: u32)                                                                                                                                                  #cc_c;
dispatch_compute_indirect:         proc(indirect: int)                                                                                                                                                                                            #cc_c;
copy_image_sub_data:                proc(srcName: u32, srcTarget: u32, srcLevel: i32, srcX: i32, srcY: i32, srcZ: i32, dstName: u32, dstTarget: u32, dstLevel: i32, dstX: i32, dstY: i32, dstZ: i32, srcWidth: i32, srcHeight: i32, srcDepth: i32) #cc_c;
framebuffer_parameter_i:           proc(target: u32, pname: u32, param: i32)                                                                                                                                                                      #cc_c;
get_framebuffer_parameter_iv:       proc(target: u32, pname: u32, params: ^i32)                                                                                                                                                                    #cc_c;
get_internalformat_i64v:           proc(target: u32, internalformat: u32, pname: u32, bufSize: i32, params: ^i64)                                                                                                                                 #cc_c;
invalidate_tex_sub_image:           proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32)                                                                                                  #cc_c;
invalidate_tex_image:              proc(texture: u32, level: i32)                                                                                                                                                                                 #cc_c;
invalidate_buffer_sub_data:         proc(buffer: u32, offset: int, length: int)                                                                                                                                                                    #cc_c;
invalidate_buffer_data:            proc(buffer: u32)                                                                                                                                                                                              #cc_c;
invalidate_framebuffer:           proc(target: u32, numAttachments: i32, attachments: ^u32)                                                                                                                                                      #cc_c;
invalidate_sub_framebuffer:        proc(target: u32, numAttachments: i32, attachments: ^u32, x: i32, y: i32, width: i32, height: i32)                                                                                                             #cc_c;
multi_draw_arrays_indirect:         proc(mode: u32, indirect: rawptr, drawcount: i32, stride: i32)                                                                                                                                                 #cc_c;
multi_draw_elements_indirect:       proc(mode: u32, type_: u32, indirect: rawptr, drawcount: i32, stride: i32)                                                                                                                                     #cc_c;
get_program_interface_iv:           proc(program: u32, programInterface: u32, pname: u32, params: ^i32)                                                                                                                                            #cc_c;
get_program_resource_index:         proc(program: u32, programInterface: u32, name: ^u8) -> u32                                                                                                                                                    #cc_c;
get_program_resource_name:          proc(program: u32, programInterface: u32, index: u32, bufSize: i32, length: ^i32, name: ^u8)                                                                                                                   #cc_c;
get_program_resource_iv:            proc(program: u32, programInterface: u32, index: u32, propCount: i32, props: ^u32, bufSize: i32, length: ^i32, params: ^i32)                                                                                   #cc_c;
get_program_resource_location:      proc(program: u32, programInterface: u32, name: ^u8) -> i32                                                                                                                                                    #cc_c;
get_program_resource_location_index: proc(program: u32, programInterface: u32, name: ^u8) -> i32                                                                                                                                                    #cc_c;
shader_storage_block_binding:       proc(program: u32, storageBlockIndex: u32, storageBlockBinding: u32)                                                                                                                                           #cc_c;
tex_buffer_range:                  proc(target: u32, internalformat: u32, buffer: u32, offset: int, size: int)                                                                                                                                    #cc_c;
tex_storage_2d_multisample:         proc(target: u32, samples: i32, internalformat: u32, width: i32, height: i32, fixedsamplelocations: u8)                                                                                                        #cc_c;
tex_storage_3d_multisample:         proc(target: u32, samples: i32, internalformat: u32, width: i32, height: i32, depth: i32, fixedsamplelocations: u8)                                                                                            #cc_c;
texture_view:                     proc(texture: u32, target: u32, origtexture: u32, internalformat: u32, minlevel: u32, numlevels: u32, minlayer: u32, numlayers: u32)                                                                           #cc_c;
bind_vertex_buffer:                proc(bindingindex: u32, buffer: u32, offset: int, stride: i32)                                                                                                                                                 #cc_c;
vertex_attrib_format:              proc(attribindex: u32, size: i32, type_: u32, normalized: u8, relativeoffset: u32)                                                                                                                             #cc_c;
vertex_attrib_i_format:             proc(attribindex: u32, size: i32, type_: u32, relativeoffset: u32)                                                                                                                                             #cc_c;
vertex_attrib_l_format:             proc(attribindex: u32, size: i32, type_: u32, relativeoffset: u32)                                                                                                                                             #cc_c;
vertex_attrib_binding:             proc(attribindex: u32, bindingindex: u32)                                                                                                                                                                      #cc_c;
vertex_binding_divisor:            proc(bindingindex: u32, divisor: u32)                                                                                                                                                                          #cc_c;
debug_message_control:             proc(source: u32, type_: u32, severity: u32, count: i32, ids: ^u32, enabled: u8)                                                                                                                               #cc_c;
debug_message_insert:              proc(source: u32, type_: u32, id: u32, severity: u32, length: i32, buf: ^u8)                                                                                                                                   #cc_c;
debug_message_callback:            proc(callback: debug_proc_t, userParam: rawptr)                                                                                                                                                                #cc_c;
get_debug_message_log:              proc(count: u32, bufSize: i32, sources: ^u32, types: ^u32, ids: ^u32, severities: ^u32, lengths: ^i32, messageLog: ^u8) -> u32                                                                                 #cc_c;
push_debug_group:                  proc(source: u32, id: u32, length: i32, message: ^u8)                                                                                                                                                          #cc_c;
pop_debug_group:                   proc()                                                                                                                                                                                                         #cc_c;
object_label:                     proc(identifier: u32, name: u32, length: i32, label: ^u8)                                                                                                                                                      #cc_c;
get_object_label:                  proc(identifier: u32, name: u32, bufSize: i32, length: ^i32, label: ^u8)                                                                                                                                       #cc_c;
object_ptr_label:                  proc(ptr: rawptr, length: i32, label: ^u8)                                                                                                                                                                     #cc_c;
get_object_ptr_label:               proc(ptr: rawptr, bufSize: i32, length: ^i32, label: ^u8)                                                                                                                                                      #cc_c;

load_4_3 :: proc() {
	_set_proc_address(&clear_buffer_data,                 "glClearBufferData\x00");
	_set_proc_address(&clear_buffer_sub_data,              "glClearBufferSubData\x00");
	_set_proc_address(&dispatch_compute,                 "glDispatchCompute\x00");
	_set_proc_address(&dispatch_compute_indirect,         "glDispatchComputeIndirect\x00");
	_set_proc_address(&copy_image_sub_data,                "glCopyImageSubData\x00");
	_set_proc_address(&framebuffer_parameter_i,           "glFramebufferParameteri\x00");
	_set_proc_address(&get_framebuffer_parameter_iv,       "glGetFramebufferParameteriv\x00");
	_set_proc_address(&get_internalformat_i64v,           "glGetInternalformati64v\x00");
	_set_proc_address(&invalidate_tex_sub_image,           "glInvalidateTexSubImage\x00");
	_set_proc_address(&invalidate_tex_image,              "glInvalidateTexImage\x00");
	_set_proc_address(&invalidate_buffer_sub_data,         "glInvalidateBufferSubData\x00");
	_set_proc_address(&invalidate_buffer_data,            "glInvalidateBufferData\x00");
	_set_proc_address(&invalidate_framebuffer,           "glInvalidateFramebuffer\x00");
	_set_proc_address(&invalidate_sub_framebuffer,        "glInvalidateSubFramebuffer\x00");
	_set_proc_address(&multi_draw_arrays_indirect,         "glMultiDrawArraysIndirect\x00");
	_set_proc_address(&multi_draw_elements_indirect,       "glMultiDrawElementsIndirect\x00");
	_set_proc_address(&get_program_interface_iv,           "glGetProgramInterfaceiv\x00");
	_set_proc_address(&get_program_resource_index,         "glGetProgramResourceIndex\x00");
	_set_proc_address(&get_program_resource_name,          "glGetProgramResourceName\x00");
	_set_proc_address(&get_program_resource_iv,            "glGetProgramResourceiv\x00");
	_set_proc_address(&get_program_resource_location,      "glGetProgramResourceLocation\x00");
	_set_proc_address(&get_program_resource_location_index, "glGetProgramResourceLocationIndex\x00");
	_set_proc_address(&shader_storage_block_binding,       "glShaderStorageBlockBinding\x00");
	_set_proc_address(&tex_buffer_range,                  "glTexBufferRange\x00");
	_set_proc_address(&tex_storage_2d_multisample,         "glTexStorage2DMultisample\x00");
	_set_proc_address(&tex_storage_3d_multisample,         "glTexStorage3DMultisample\x00");
	_set_proc_address(&texture_view,                     "glTextureView\x00");
	_set_proc_address(&bind_vertex_buffer,                "glBindVertexBuffer\x00");
	_set_proc_address(&vertex_attrib_format,              "glVertexAttribFormat\x00");
	_set_proc_address(&vertex_attrib_i_format,             "glVertexAttribIFormat\x00");
	_set_proc_address(&vertex_attrib_l_format,             "glVertexAttribLFormat\x00");
	_set_proc_address(&vertex_attrib_binding,             "glVertexAttribBinding\x00");
	_set_proc_address(&vertex_binding_divisor,            "glVertexBindingDivisor\x00");
	_set_proc_address(&debug_message_control,             "glDebugMessageControl\x00");
	_set_proc_address(&debug_message_insert,              "glDebugMessageInsert\x00");
	_set_proc_address(&debug_message_callback,            "glDebugMessageCallback\x00");
	_set_proc_address(&get_debug_message_log,              "glGetDebugMessageLog\x00");
	_set_proc_address(&push_debug_group,                  "glPushDebugGroup\x00");
	_set_proc_address(&pop_debug_group,                   "glPopDebugGroup\x00");
	_set_proc_address(&object_label,                     "glObjectLabel\x00");
	_set_proc_address(&get_object_label,                  "glGetObjectLabel\x00");
	_set_proc_address(&object_ptr_label,                  "glObjectPtrLabel\x00");
	_set_proc_address(&get_object_ptr_label,               "glGetObjectPtrLabel\x00");
}

// VERSION_4_4
buffer_storage:     proc(target: u32, size: int, data: rawptr, flags: u32)                                                                                               #cc_c;
clear_tex_image:     proc(texture: u32, level: i32, format: u32, type_: u32, data: rawptr)                                                                                #cc_c;
clear_tex_sub_image:  proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, type_: u32, data: rawptr) #cc_c;
bind_buffers_base:   proc(target: u32, first: u32, count: i32, buffers: ^u32)                                                                                             #cc_c;
bind_buffers_range:  proc(target: u32, first: u32, count: i32, buffers: ^u32, offsets: ^int, sizes: ^int)                                                                 #cc_c;
bind_textures:      proc(first: u32, count: i32, textures: ^u32)                                                                                                         #cc_c;
bind_samplers:      proc(first: u32, count: i32, samplers: ^u32)                                                                                                         #cc_c;
bind_image_textures: proc(first: u32, count: i32, textures: ^u32)                                                                                                         #cc_c;
bind_vertex_buffers: proc(first: u32, count: i32, buffers: ^u32, offsets: ^int, strides: ^i32)                                                                            #cc_c;

load_4_4 :: proc() {
	_set_proc_address(&buffer_storage,     "glBufferStorage\x00");
	_set_proc_address(&clear_tex_image,     "glClearTexImage\x00");
	_set_proc_address(&clear_tex_sub_image,  "glClearTexSubImage\x00");
	_set_proc_address(&bind_buffers_base,   "glBindBuffersBase\x00");
	_set_proc_address(&bind_buffers_range,  "glBindBuffersRange\x00");
	_set_proc_address(&bind_textures,      "glBindTextures\x00");
	_set_proc_address(&bind_samplers,      "glBindSamplers\x00");
	_set_proc_address(&bind_image_textures, "glBindImageTextures\x00");
	_set_proc_address(&bind_vertex_buffers, "glBindVertexBuffers\x00");
}

// VERSION_4_5
clip_control:                              proc(origin: u32, depth: u32)                                                                                                                                            #cc_c;
create_transform_feedbacks:                 proc(n: i32, ids: ^u32)                                                                                                                                                  #cc_c;
transform_feedback_buffer_base:              proc(xfb: u32, index: u32, buffer: u32)                                                                                                                                  #cc_c;
transform_feedback_buffer_range:             proc(xfb: u32, index: u32, buffer: u32, offset: int, size: int)                                                                                                          #cc_c;
get_transform_feedback_iv:                   proc(xfb: u32, pname: u32, param: ^i32)                                                                                                                                  #cc_c;
get_transform_feedbacki_v:                  proc(xfb: u32, pname: u32, index: u32, param: ^i32)                                                                                                                      #cc_c;
get_transform_feedbacki64_v:                proc(xfb: u32, pname: u32, index: u32, param: ^i64)                                                                                                                      #cc_c;
create_buffers:                            proc(n: i32, buffers: ^u32)                                                                                                                                              #cc_c;
named_buffer_storage:                       proc(buffer: u32, size: int, data: rawptr, flags: u32)                                                                                                                   #cc_c;
named_buffer_data:                          proc(buffer: u32, size: int, data: rawptr, usage: u32)                                                                                                                   #cc_c;
named_buffer_sub_data:                       proc(buffer: u32, offset: int, size: int, data: rawptr)                                                                                                                  #cc_c;
copy_named_buffer_sub_data:                   proc(readBuffer: u32, writeBuffer: u32, readOffset: int, writeOffset: int, size: int)                                                                                    #cc_c;
clear_named_buffer_data:                     proc(buffer: u32, internalformat: u32, format: u32, type_: u32, data: rawptr)                                                                                            #cc_c;
clear_named_buffer_sub_data:                  proc(buffer: u32, internalformat: u32, offset: int, size: int, format: u32, type_: u32, data: rawptr)                                                                    #cc_c;
map_named_buffer:                           proc(buffer: u32, access: u32) -> rawptr                                                                                                                                 #cc_c;
map_named_buffer_range:                      proc(buffer: u32, offset: int, length: int, access: u32) -> rawptr                                                                                                       #cc_c;
unmap_named_buffer:                         proc(buffer: u32) -> u8                                                                                                                                                  #cc_c;
flush_mapped_named_buffer_range:              proc(buffer: u32, offset: int, length: int)                                                                                                                              #cc_c;
get_named_buffer_parameter_iv:                proc(buffer: u32, pname: u32, params: ^i32)                                                                                                                              #cc_c;
get_named_buffer_parameter_i64v:              proc(buffer: u32, pname: u32, params: ^i64)                                                                                                                              #cc_c;
get_named_buffer_pointer_v:                   proc(buffer: u32, pname: u32, params: ^rawptr)                                                                                                                           #cc_c;
get_named_buffer_sub_data:                    proc(buffer: u32, offset: int, size: int, data: rawptr)                                                                                                                  #cc_c;
create_framebuffers:                       proc(n: i32, framebuffers: ^u32)                                                                                                                                         #cc_c;
named_framebuffer_renderbuffer:             proc(framebuffer: u32, attachment: u32, renderbuffertarget: u32, renderbuffer: u32)                                                                                      #cc_c;
named_framebuffer_parameter_i:               proc(framebuffer: u32, pname: u32, param: i32)                                                                                                                           #cc_c;
named_framebuffer_texture:                  proc(framebuffer: u32, attachment: u32, texture: u32, level: i32)                                                                                                        #cc_c;
named_framebuffer_texture_layer:             proc(framebuffer: u32, attachment: u32, texture: u32, level: i32, layer: i32)                                                                                            #cc_c;
named_framebuffer_draw_buffer:               proc(framebuffer: u32, buf: u32)                                                                                                                                         #cc_c;
named_framebuffer_draw_buffers:              proc(framebuffer: u32, n: i32, bufs: ^u32)                                                                                                                               #cc_c;
named_framebuffer_read_buffer:               proc(framebuffer: u32, src: u32)                                                                                                                                         #cc_c;
invalidate_named_framebuffer_data:           proc(framebuffer: u32, numAttachments: i32, attachments: ^u32)                                                                                                           #cc_c;
invalidate_named_framebuffer_sub_data:        proc(framebuffer: u32, numAttachments: i32, attachments: ^u32, x: i32, y: i32, width: i32, height: i32)                                                                  #cc_c;
clear_named_framebuffer_iv:                  proc(framebuffer: u32, buffer: u32, drawbuffer: i32, value: ^i32)                                                                                                        #cc_c;
clear_named_framebuffer_uiv:                 proc(framebuffer: u32, buffer: u32, drawbuffer: i32, value: ^u32)                                                                                                        #cc_c;
clear_named_framebuffer_fv:                  proc(framebuffer: u32, buffer: u32, drawbuffer: i32, value: ^f32)                                                                                                        #cc_c;
clear_named_framebuffer_fi:                  proc(framebuffer: u32, buffer: u32, drawbuffer: i32, depth: f32, stencil: i32)                                                                                           #cc_c;
blit_named_framebuffer:                     proc(readFramebuffer: u32, drawFramebuffer: u32, srcX0: i32, srcY0: i32, srcX1: i32, srcY1: i32, dstX0: i32, dstY0: i32, dstX1: i32, dstY1: i32, mask: u32, filter: u32) #cc_c;
check_named_framebuffer_status:              proc(framebuffer: u32, target: u32) -> u32                                                                                                                               #cc_c;
get_named_framebuffer_parameter_iv:           proc(framebuffer: u32, pname: u32, param: ^i32)                                                                                                                          #cc_c;
get_named_framebuffer_attachment_parameter_iv: proc(framebuffer: u32, attachment: u32, pname: u32, params: ^i32)                                                                                                        #cc_c;
create_renderbuffers:                      proc(n: i32, renderbuffers: ^u32)                                                                                                                                        #cc_c;
named_renderbuffer_storage:                 proc(renderbuffer: u32, internalformat: u32, width: i32, height: i32)                                                                                                    #cc_c;
named_renderbuffer_storage_multisample:      proc(renderbuffer: u32, samples: i32, internalformat: u32, width: i32, height: i32)                                                                                      #cc_c;
get_named_renderbuffer_parameter_iv:          proc(renderbuffer: u32, pname: u32, params: ^i32)                                                                                                                        #cc_c;
create_textures:                           proc(target: u32, n: i32, textures: ^u32)                                                                                                                                #cc_c;
texture_buffer:                            proc(texture: u32, internalformat: u32, buffer: u32)                                                                                                                     #cc_c;
texture_buffer_range:                       proc(texture: u32, internalformat: u32, buffer: u32, offset: int, size: int)                                                                                             #cc_c;
texture_storage_1d:                         proc(texture: u32, levels: i32, internalformat: u32, width: i32)                                                                                                         #cc_c;
texture_storage_2d:                         proc(texture: u32, levels: i32, internalformat: u32, width: i32, height: i32)                                                                                            #cc_c;
texture_storage_3d:                         proc(texture: u32, levels: i32, internalformat: u32, width: i32, height: i32, depth: i32)                                                                                #cc_c;
texture_storage_2d_multisample:              proc(texture: u32, samples: i32, internalformat: u32, width: i32, height: i32, fixedsamplelocations: u8)                                                                 #cc_c;
texture_storage_3d_multisample:              proc(texture: u32, samples: i32, internalformat: u32, width: i32, height: i32, depth: i32, fixedsamplelocations: u8)                                                     #cc_c;
texture_sub_image_1d:                        proc(texture: u32, level: i32, xoffset: i32, width: i32, format: u32, type_: u32, pixels: rawptr)                                                                        #cc_c;
texture_sub_image_2d:                        proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, type_: u32, pixels: rawptr)                                             #cc_c;
texture_sub_image_3d:                        proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, type_: u32, pixels: rawptr)                   #cc_c;
compressed_texture_sub_image_1d:              proc(texture: u32, level: i32, xoffset: i32, width: i32, format: u32, imageSize: i32, data: rawptr)                                                                      #cc_c;
compressed_texture_sub_image_2d:              proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, imageSize: i32, data: rawptr)                                           #cc_c;
compressed_texture_sub_image_3d:              proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, imageSize: i32, data: rawptr)                 #cc_c;
copy_texture_sub_image_1d:                    proc(texture: u32, level: i32, xoffset: i32, x: i32, y: i32, width: i32)                                                                                                 #cc_c;
copy_texture_sub_image_2d:                    proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, x: i32, y: i32, width: i32, height: i32)                                                                      #cc_c;
copy_texture_sub_image_3d:                    proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, x: i32, y: i32, width: i32, height: i32)                                                        #cc_c;
texture_parameter_f:                        proc(texture: u32, pname: u32, param: f32)                                                                                                                               #cc_c;
texture_parameter_fv:                       proc(texture: u32, pname: u32, param: ^f32)                                                                                                                              #cc_c;
texture_parameter_i:                        proc(texture: u32, pname: u32, param: i32)                                                                                                                               #cc_c;
texture_parameter_iiv:                      proc(texture: u32, pname: u32, params: ^i32)                                                                                                                             #cc_c;
texture_parameter_iuiv:                     proc(texture: u32, pname: u32, params: ^u32)                                                                                                                             #cc_c;
texture_parameter_iv:                       proc(texture: u32, pname: u32, param: ^i32)                                                                                                                              #cc_c;
generate_texture_mipmap:                    proc(texture: u32)                                                                                                                                                       #cc_c;
bind_texture_unit:                          proc(unit: u32, texture: u32)                                                                                                                                            #cc_c;
get_texture_image:                          proc(texture: u32, level: i32, format: u32, type_: u32, bufSize: i32, pixels: rawptr)                                                                                    #cc_c;
get_compressed_texture_image:                proc(texture: u32, level: i32, bufSize: i32, pixels: rawptr)                                                                                                             #cc_c;
get_texture_level_parameter_fv:               proc(texture: u32, level: i32, pname: u32, params: ^f32)                                                                                                                 #cc_c;
get_texture_level_parameter_iv:               proc(texture: u32, level: i32, pname: u32, params: ^i32)                                                                                                                 #cc_c;
get_texture_parameter_fv:                    proc(texture: u32, pname: u32, params: ^f32)                                                                                                                             #cc_c;
get_texture_parameter_iiv:                   proc(texture: u32, pname: u32, params: ^i32)                                                                                                                             #cc_c;
get_texture_parameter_iuiv:                  proc(texture: u32, pname: u32, params: ^u32)                                                                                                                             #cc_c;
get_texture_parameter_iv:                    proc(texture: u32, pname: u32, params: ^i32)                                                                                                                             #cc_c;
create_vertex_arrays:                       proc(n: i32, arrays: ^u32)                                                                                                                                               #cc_c;
disable_vertex_array_attrib:                 proc(vaobj: u32, index: u32)                                                                                                                                             #cc_c;
enable_vertex_array_attrib:                  proc(vaobj: u32, index: u32)                                                                                                                                             #cc_c;
vertex_array_element_buffer:                 proc(vaobj: u32, buffer: u32)                                                                                                                                            #cc_c;
vertex_array_vertex_buffer:                  proc(vaobj: u32, bindingindex: u32, buffer: u32, offset: int, stride: i32)                                                                                               #cc_c;
vertex_array_vertex_buffers:                 proc(vaobj: u32, first: u32, count: i32, buffers: ^u32, offsets: ^int, strides: ^i32)                                                                                    #cc_c;
vertex_array_attrib_binding:                 proc(vaobj: u32, attribindex: u32, bindingindex: u32)                                                                                                                    #cc_c;
vertex_array_attrib_format:                  proc(vaobj: u32, attribindex: u32, size: i32, type_: u32, normalized: u8, relativeoffset: u32)                                                                           #cc_c;
vertex_array_attrib_i_format:                 proc(vaobj: u32, attribindex: u32, size: i32, type_: u32, relativeoffset: u32)                                                                                           #cc_c;
vertex_array_attrib_l_format:                 proc(vaobj: u32, attribindex: u32, size: i32, type_: u32, relativeoffset: u32)                                                                                           #cc_c;
vertex_array_binding_divisor:                proc(vaobj: u32, bindingindex: u32, divisor: u32)                                                                                                                        #cc_c;
get_vertex_array_iv:                         proc(vaobj: u32, pname: u32, param: ^i32)                                                                                                                                #cc_c;
get_vertex_array_indexed_iv:                  proc(vaobj: u32, index: u32, pname: u32, param: ^i32)                                                                                                                    #cc_c;
get_vertex_array_indexed64_iv:                proc(vaobj: u32, index: u32, pname: u32, param: ^i64)                                                                                                                    #cc_c;
create_samplers:                           proc(n: i32, samplers: ^u32)                                                                                                                                             #cc_c;
create_program_pipelines:                   proc(n: i32, pipelines: ^u32)                                                                                                                                            #cc_c;
create_queries:                            proc(target: u32, n: i32, ids: ^u32)                                                                                                                                     #cc_c;
get_query_buffer_object_i64v:                 proc(id: u32, buffer: u32, pname: u32, offset: int)                                                                                                                      #cc_c;
get_query_buffer_object_iv:                   proc(id: u32, buffer: u32, pname: u32, offset: int)                                                                                                                      #cc_c;
get_query_buffer_object_ui64v:                proc(id: u32, buffer: u32, pname: u32, offset: int)                                                                                                                      #cc_c;
get_query_buffer_object_uiv:                  proc(id: u32, buffer: u32, pname: u32, offset: int)                                                                                                                      #cc_c;
memory_barrier_by_region:                    proc(barriers: u32)                                                                                                                                                      #cc_c;
get_texture_sub_image:                       proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, type_: u32, bufSize: i32, pixels: rawptr)     #cc_c;
get_compressed_texture_sub_image:             proc(texture: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, bufSize: i32, pixels: rawptr)                              #cc_c;
get_graphics_reset_status:                   proc() -> u32                                                                                                                                                            #cc_c;
getn_compressed_tex_image:                   proc(target: u32, lod: i32, bufSize: i32, pixels: rawptr)                                                                                                                #cc_c;
getn_tex_image:                             proc(target: u32, level: i32, format: u32, type_: u32, bufSize: i32, pixels: rawptr)                                                                                     #cc_c;
getn_uniform_dv:                            proc(program: u32, location: i32, bufSize: i32, params: ^f64)                                                                                                            #cc_c;
getn_uniform_fv:                            proc(program: u32, location: i32, bufSize: i32, params: ^f32)                                                                                                            #cc_c;
getn_uniform_iv:                            proc(program: u32, location: i32, bufSize: i32, params: ^i32)                                                                                                            #cc_c;
getn_uniform_uiv:                           proc(program: u32, location: i32, bufSize: i32, params: ^u32)                                                                                                            #cc_c;
readn_pixels:                              proc(x: i32, y: i32, width: i32, height: i32, format: u32, type_: u32, bufSize: i32, data: rawptr)                                                                       #cc_c;
getn_map_dv:                                proc(target: u32, query: u32, bufSize: i32, v: ^f64)                                                                                                                     #cc_c;
getn_map_fv:                                proc(target: u32, query: u32, bufSize: i32, v: ^f32)                                                                                                                     #cc_c;
getn_map_iv:                                proc(target: u32, query: u32, bufSize: i32, v: ^i32)                                                                                                                     #cc_c;
getn_pixel_map_usv:                          proc(map_: u32, bufSize: i32, values: ^u16)                                                                                                                              #cc_c;
getn_pixel_map_fv:                           proc(map_: u32, bufSize: i32, values: ^f32)                                                                                                                              #cc_c;
getn_pixel_map_uiv:                          proc(map_: u32, bufSize: i32, values: ^u32)                                                                                                                              #cc_c;
getn_polygon_stipple:                       proc(bufSize: i32, pattern: ^u8)                                                                                                                                         #cc_c;
getn_color_table:                           proc(target: u32, format: u32, type_: u32, bufSize: i32, table: rawptr)                                                                                                  #cc_c;
getn_convolution_filter:                    proc(target: u32, format: u32, type_: u32, bufSize: i32, image: rawptr)                                                                                                  #cc_c;
getn_separable_filter:                      proc(target: u32, format: u32, type_: u32, rowBufSize: i32, row: rawptr, columnBufSize: i32, column: rawptr, span: rawptr)                                               #cc_c;
getn_histogram:                            proc(target: u32, reset: u8, format: u32, type_: u32, bufSize: i32, values: rawptr)                                                                                      #cc_c;
getn_minmax:                               proc(target: u32, reset: u8, format: u32, type_: u32, bufSize: i32, values: rawptr)                                                                                      #cc_c;
texture_barrier:                           proc()                                                                                                                                                                   #cc_c;

load_4_5 :: proc() {
	_set_proc_address(&clip_control,                              "glClipControl\x00");
	_set_proc_address(&create_transform_feedbacks,                 "glCreateTransformFeedbacks\x00");
	_set_proc_address(&transform_feedback_buffer_base,              "glTransformFeedbackBufferBase\x00");
	_set_proc_address(&transform_feedback_buffer_range,             "glTransformFeedbackBufferRange\x00");
	_set_proc_address(&get_transform_feedback_iv,                   "glGetTransformFeedbackiv\x00");
	_set_proc_address(&get_transform_feedbacki_v,                  "glGetTransformFeedbacki_v\x00");
	_set_proc_address(&get_transform_feedbacki64_v,                "glGetTransformFeedbacki64_v\x00");
	_set_proc_address(&create_buffers,                            "glCreateBuffers\x00");
	_set_proc_address(&named_buffer_storage,                       "glNamedBufferStorage\x00");
	_set_proc_address(&named_buffer_data,                          "glNamedBufferData\x00");
	_set_proc_address(&named_buffer_sub_data,                       "glNamedBufferSubData\x00");
	_set_proc_address(&copy_named_buffer_sub_data,                   "glCopyNamedBufferSubData\x00");
	_set_proc_address(&clear_named_buffer_data,                     "glClearNamedBufferData\x00");
	_set_proc_address(&clear_named_buffer_sub_data,                  "glClearNamedBufferSubData\x00");
	_set_proc_address(&map_named_buffer,                           "glMapNamedBuffer\x00");
	_set_proc_address(&map_named_buffer_range,                      "glMapNamedBufferRange\x00");
	_set_proc_address(&unmap_named_buffer,                         "glUnmapNamedBuffer\x00");
	_set_proc_address(&flush_mapped_named_buffer_range,              "glFlushMappedNamedBufferRange\x00");
	_set_proc_address(&get_named_buffer_parameter_iv,                "glGetNamedBufferParameteriv\x00");
	_set_proc_address(&get_named_buffer_parameter_i64v,              "glGetNamedBufferParameteri64v\x00");
	_set_proc_address(&get_named_buffer_pointer_v,                   "glGetNamedBufferPointerv\x00");
	_set_proc_address(&get_named_buffer_sub_data,                    "glGetNamedBufferSubData\x00");
	_set_proc_address(&create_framebuffers,                       "glCreateFramebuffers\x00");
	_set_proc_address(&named_framebuffer_renderbuffer,             "glNamedFramebufferRenderbuffer\x00");
	_set_proc_address(&named_framebuffer_parameter_i,               "glNamedFramebufferParameteri\x00");
	_set_proc_address(&named_framebuffer_texture,                  "glNamedFramebufferTexture\x00");
	_set_proc_address(&named_framebuffer_texture_layer,             "glNamedFramebufferTextureLayer\x00");
	_set_proc_address(&named_framebuffer_draw_buffer,               "glNamedFramebufferDrawBuffer\x00");
	_set_proc_address(&named_framebuffer_draw_buffers,              "glNamedFramebufferDrawBuffers\x00");
	_set_proc_address(&named_framebuffer_read_buffer,               "glNamedFramebufferReadBuffer\x00");
	_set_proc_address(&invalidate_named_framebuffer_data,           "glInvalidateNamedFramebufferData\x00");
	_set_proc_address(&invalidate_named_framebuffer_sub_data,        "glInvalidateNamedFramebufferSubData\x00");
	_set_proc_address(&clear_named_framebuffer_iv,                  "glClearNamedFramebufferiv\x00");
	_set_proc_address(&clear_named_framebuffer_uiv,                 "glClearNamedFramebufferuiv\x00");
	_set_proc_address(&clear_named_framebuffer_fv,                  "glClearNamedFramebufferfv\x00");
	_set_proc_address(&clear_named_framebuffer_fi,                  "glClearNamedFramebufferfi\x00");
	_set_proc_address(&blit_named_framebuffer,                     "glBlitNamedFramebuffer\x00");
	_set_proc_address(&check_named_framebuffer_status,              "glCheckNamedFramebufferStatus\x00");
	_set_proc_address(&get_named_framebuffer_parameter_iv,           "glGetNamedFramebufferParameteriv\x00");
	_set_proc_address(&get_named_framebuffer_attachment_parameter_iv, "glGetNamedFramebufferAttachmentParameteriv\x00");
	_set_proc_address(&create_renderbuffers,                      "glCreateRenderbuffers\x00");
	_set_proc_address(&named_renderbuffer_storage,                 "glNamedRenderbufferStorage\x00");
	_set_proc_address(&named_renderbuffer_storage_multisample,      "glNamedRenderbufferStorageMultisample\x00");
	_set_proc_address(&get_named_renderbuffer_parameter_iv,          "glGetNamedRenderbufferParameteriv\x00");
	_set_proc_address(&create_textures,                           "glCreateTextures\x00");
	_set_proc_address(&texture_buffer,                            "glTextureBuffer\x00");
	_set_proc_address(&texture_buffer_range,                       "glTextureBufferRange\x00");
	_set_proc_address(&texture_storage_1d,                         "glTextureStorage1D\x00");
	_set_proc_address(&texture_storage_2d,                         "glTextureStorage2D\x00");
	_set_proc_address(&texture_storage_3d,                         "glTextureStorage3D\x00");
	_set_proc_address(&texture_storage_2d_multisample,              "glTextureStorage2DMultisample\x00");
	_set_proc_address(&texture_storage_3d_multisample,              "glTextureStorage3DMultisample\x00");
	_set_proc_address(&texture_sub_image_1d,                        "glTextureSubImage1D\x00");
	_set_proc_address(&texture_sub_image_2d,                        "glTextureSubImage2D\x00");
	_set_proc_address(&texture_sub_image_3d,                        "glTextureSubImage3D\x00");
	_set_proc_address(&compressed_texture_sub_image_1d,              "glCompressedTextureSubImage1D\x00");
	_set_proc_address(&compressed_texture_sub_image_2d,              "glCompressedTextureSubImage2D\x00");
	_set_proc_address(&compressed_texture_sub_image_3d,              "glCompressedTextureSubImage3D\x00");
	_set_proc_address(&copy_texture_sub_image_1d,                    "glCopyTextureSubImage1D\x00");
	_set_proc_address(&copy_texture_sub_image_2d,                    "glCopyTextureSubImage2D\x00");
	_set_proc_address(&copy_texture_sub_image_3d,                    "glCopyTextureSubImage3D\x00");
	_set_proc_address(&texture_parameter_f,                        "glTextureParameterf\x00");
	_set_proc_address(&texture_parameter_fv,                       "glTextureParameterfv\x00");
	_set_proc_address(&texture_parameter_i,                        "glTextureParameteri\x00");
	_set_proc_address(&texture_parameter_iiv,                      "glTextureParameterIiv\x00");
	_set_proc_address(&texture_parameter_iuiv,                     "glTextureParameterIuiv\x00");
	_set_proc_address(&texture_parameter_iv,                       "glTextureParameteriv\x00");
	_set_proc_address(&generate_texture_mipmap,                    "glGenerateTextureMipmap\x00");
	_set_proc_address(&bind_texture_unit,                          "glBindTextureUnit\x00");
	_set_proc_address(&get_texture_image,                          "glGetTextureImage\x00");
	_set_proc_address(&get_compressed_texture_image,                "glGetCompressedTextureImage\x00");
	_set_proc_address(&get_texture_level_parameter_fv,               "glGetTextureLevelParameterfv\x00");
	_set_proc_address(&get_texture_level_parameter_iv,               "glGetTextureLevelParameteriv\x00");
	_set_proc_address(&get_texture_parameter_fv,                    "glGetTextureParameterfv\x00");
	_set_proc_address(&get_texture_parameter_iiv,                   "glGetTextureParameterIiv\x00");
	_set_proc_address(&get_texture_parameter_iuiv,                  "glGetTextureParameterIuiv\x00");
	_set_proc_address(&get_texture_parameter_iv,                    "glGetTextureParameteriv\x00");
	_set_proc_address(&create_vertex_arrays,                       "glCreateVertexArrays\x00");
	_set_proc_address(&disable_vertex_array_attrib,                 "glDisableVertexArrayAttrib\x00");
	_set_proc_address(&enable_vertex_array_attrib,                  "glEnableVertexArrayAttrib\x00");
	_set_proc_address(&vertex_array_element_buffer,                 "glVertexArrayElementBuffer\x00");
	_set_proc_address(&vertex_array_vertex_buffer,                  "glVertexArrayVertexBuffer\x00");
	_set_proc_address(&vertex_array_vertex_buffers,                 "glVertexArrayVertexBuffers\x00");
	_set_proc_address(&vertex_array_attrib_binding,                 "glVertexArrayAttribBinding\x00");
	_set_proc_address(&vertex_array_attrib_format,                  "glVertexArrayAttribFormat\x00");
	_set_proc_address(&vertex_array_attrib_i_format,                 "glVertexArrayAttribIFormat\x00");
	_set_proc_address(&vertex_array_attrib_l_format,                 "glVertexArrayAttribLFormat\x00");
	_set_proc_address(&vertex_array_binding_divisor,                "glVertexArrayBindingDivisor\x00");
	_set_proc_address(&get_vertex_array_iv,                         "glGetVertexArrayiv\x00");
	_set_proc_address(&get_vertex_array_indexed_iv,                  "glGetVertexArrayIndexediv\x00");
	_set_proc_address(&get_vertex_array_indexed64_iv,                "glGetVertexArrayIndexed64iv\x00");
	_set_proc_address(&create_samplers,                           "glCreateSamplers\x00");
	_set_proc_address(&create_program_pipelines,                   "glCreateProgramPipelines\x00");
	_set_proc_address(&create_queries,                            "glCreateQueries\x00");
	_set_proc_address(&get_query_buffer_object_i64v,                 "glGetQueryBufferObjecti64v\x00");
	_set_proc_address(&get_query_buffer_object_iv,                   "glGetQueryBufferObjectiv\x00");
	_set_proc_address(&get_query_buffer_object_ui64v,                "glGetQueryBufferObjectui64v\x00");
	_set_proc_address(&get_query_buffer_object_uiv,                  "glGetQueryBufferObjectuiv\x00");
	_set_proc_address(&memory_barrier_by_region,                    "glMemoryBarrierByRegion\x00");
	_set_proc_address(&get_texture_sub_image,                       "glGetTextureSubImage\x00");
	_set_proc_address(&get_compressed_texture_sub_image,             "glGetCompressedTextureSubImage\x00");
	_set_proc_address(&get_graphics_reset_status,                   "glGetGraphicsResetStatus\x00");
	_set_proc_address(&getn_compressed_tex_image,                   "glGetnCompressedTexImage\x00");
	_set_proc_address(&getn_tex_image,                             "glGetnTexImage\x00");
	_set_proc_address(&getn_uniform_dv,                            "glGetnUniformdv\x00");
	_set_proc_address(&getn_uniform_fv,                            "glGetnUniformfv\x00");
	_set_proc_address(&getn_uniform_iv,                            "glGetnUniformiv\x00");
	_set_proc_address(&getn_uniform_uiv,                           "glGetnUniformuiv\x00");
	_set_proc_address(&readn_pixels,                              "glReadnPixels\x00");
	_set_proc_address(&getn_map_dv,                                "glGetnMapdv\x00");
	_set_proc_address(&getn_map_fv,                                "glGetnMapfv\x00");
	_set_proc_address(&getn_map_iv,                                "glGetnMapiv\x00");
	_set_proc_address(&getn_pixel_map_fv,                           "glGetnPixelMapfv\x00");
	_set_proc_address(&getn_pixel_map_uiv,                          "glGetnPixelMapuiv\x00");
	_set_proc_address(&getn_pixel_map_usv,                          "glGetnPixelMapusv\x00");
	_set_proc_address(&getn_polygon_stipple,                       "glGetnPolygonStipple\x00");
	_set_proc_address(&getn_color_table,                           "glGetnColorTable\x00");
	_set_proc_address(&getn_convolution_filter,                    "glGetnConvolutionFilter\x00");
	_set_proc_address(&getn_separable_filter,                      "glGetnSeparableFilter\x00");
	_set_proc_address(&getn_histogram,                            "glGetnHistogram\x00");
	_set_proc_address(&getn_minmax,                               "glGetnMinmax\x00");
	_set_proc_address(&texture_barrier,                           "glTextureBarrier\x00");
}

init :: proc() {
	// Placeholder for loading maximum supported version
}


// Helper for loading shaders into a program

load_shaders :: proc(vertex_shader_filename, fragment_shader_filename: string) -> (program: u32, success: bool) {
	// Shader checking and linking checking are identical 
	// except for calling differently named GL functions
	// it's a bit ugly looking, but meh
	check_error :: proc(id: u32, status: u32, 
					 iv_func: proc(u32, u32, ^i32) #cc_c, 
					 log_func: proc(u32, i32, ^i32, ^u8) #cc_c) -> (bool) {
		result, info_log_length : i32;
		iv_func(id, status, &result);
		iv_func(id, INFO_LOG_LENGTH, &info_log_length);

		if result == 0 {
			error_message := make([]u8, info_log_length);
			defer free(error_message);

			log_func(id, i32(info_log_length), nil, &error_message[0]);
			fmt.printf(string(error_message[0..len(error_message)-1])); 

			return true;
		}

		return false;
	}

	// Compiling shaders are identical for any shader (vertex, geometry, fragment, tesselation, (maybe compute too))
	compile_shader_from_file :: proc(shader_filename: string, shader_type: u32) -> (u32, bool) {
		shader_code, ok := os.read_entire_file(shader_filename);
		if !ok {
			fmt.printf("Could not load file \"%s\"\n", shader_filename);
			return 0, false;
		}
		defer free(shader_code);

		shader_id := create_shader(shader_type);
		length := i32(len(shader_code));
		shader_source(shader_id, 1, cast(^^u8)&shader_code, &length);
		compile_shader(shader_id);

		if (check_error(shader_id, COMPILE_STATUS, get_shader_iv, get_shader_info_log)) {
			return 0, false;
		}

		return shader_id, true;
	}

	// only used once, but I'd just make a subprocedure(?) for consistency
	create_and_link_program :: proc(shader_ids: []u32) -> (u32, bool) {
		program_id := create_program();
		for id in shader_ids {
			attach_shader(program_id, id);   
		}
		link_program(program_id);

		if (check_error(program_id, LINK_STATUS, get_program_iv, get_program_info_log)) {
			return 0, false;
		}

		return program_id, true;
	}

	// actual function from here
	vertex_shader_id, ok1 := compile_shader_from_file(vertex_shader_filename, VERTEX_SHADER);
	defer delete_shader(vertex_shader_id);

	fragment_shader_id, ok2 := compile_shader_from_file(fragment_shader_filename, FRAGMENT_SHADER);
	defer delete_shader(fragment_shader_id);

	if (!ok1 || !ok2) {
		return 0, false;
	}

	program_id, ok := create_and_link_program([]u32{vertex_shader_id, fragment_shader_id});
	if (!ok) {
		return 0, false;
	}

	return program_id, true;
}



import "core:strings.odin";


Uniform_Type :: enum i32 {
	FLOAT = 0x1406,
	FLOAT_VEC2 = 0x8B50,
	FLOAT_VEC3 = 0x8B51,
	FLOAT_VEC4 = 0x8B52,
	
	DOUBLE = 0x140A,
	DOUBLE_VEC2 = 0x8FFC,
	DOUBLE_VEC3 = 0x8FFD,
	DOUBLE_VEC4 = 0x8FFE,
	
	INT = 0x1404,
	INT_VEC2 = 0x8B53,
	INT_VEC3 = 0x8B54,
	INT_VEC4 = 0x8B55,

	UNSIGNED_INT = 0x1405,
	UNSIGNED_INT_VEC2 = 0x8DC6,
	UNSIGNED_INT_VEC3 = 0x8DC7,
	UNSIGNED_INT_VEC4 = 0x8DC8,

	BOOL = 0x8B56,
	BOOL_VEC2 = 0x8B57,
	BOOL_VEC3 = 0x8B58,
	BOOL_VEC4 = 0x8B59,

	FLOAT_MAT2 = 0x8B5A,
	FLOAT_MAT3 = 0x8B5B,
	FLOAT_MAT4 = 0x8B5C,
	FLOAT_MAT2x3 = 0x8B65,
	FLOAT_MAT2x4 = 0x8B66,
	FLOAT_MAT3x2 = 0x8B67,
	FLOAT_MAT3x4 = 0x8B68,
	FLOAT_MAT4x2 = 0x8B69,
	FLOAT_MAT4x3 = 0x8B6A,

	DOUBLE_MAT2 = 0x8F46,
	DOUBLE_MAT3 = 0x8F47,
	DOUBLE_MAT4 = 0x8F48,
	DOUBLE_MAT2x3 = 0x8F49,
	DOUBLE_MAT2x4 = 0x8F4A,
	DOUBLE_MAT3x2 = 0x8F4B,
	DOUBLE_MAT3x4 = 0x8F4C,
	DOUBLE_MAT4x2 = 0x8F4D,
	DOUBLE_MAT4x3 = 0x8F4E,

	SAMPLER_1D = 0x8B5D,
	SAMPLER_2D = 0x8B5E,
	SAMPLER_3D = 0x8B5F,
	SAMPLER_CUBE = 0x8B60,
	SAMPLER_1D_SHADOW = 0x8B61,
	SAMPLER_2D_SHADOW = 0x8B62,
	SAMPLER_1D_ARRAY = 0x8DC0,
	SAMPLER_2D_ARRAY = 0x8DC1,
	SAMPLER_1D_ARRAY_SHADOW = 0x8DC3,
	SAMPLER_2D_ARRAY_SHADOW = 0x8DC4,
	SAMPLER_2D_MULTISAMPLE = 0x9108,
	SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910B,
	SAMPLER_CUBE_SHADOW = 0x8DC5,
	SAMPLER_BUFFER = 0x8DC2,
	SAMPLER_2D_RECT = 0x8B63,
	SAMPLER_2D_RECT_SHADOW = 0x8B64,

	INT_SAMPLER_1D = 0x8DC9,
	INT_SAMPLER_2D = 0x8DCA,
	INT_SAMPLER_3D = 0x8DCB,
	INT_SAMPLER_CUBE = 0x8DCC,
	INT_SAMPLER_1D_ARRAY = 0x8DCE,
	INT_SAMPLER_2D_ARRAY = 0x8DCF,
	INT_SAMPLER_2D_MULTISAMPLE = 0x9109,
	INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910C,
	INT_SAMPLER_BUFFER = 0x8DD0,
	INT_SAMPLER_2D_RECT = 0x8DCD,

	UNSIGNED_INT_SAMPLER_1D = 0x8DD1,
	UNSIGNED_INT_SAMPLER_2D = 0x8DD2,
	UNSIGNED_INT_SAMPLER_3D = 0x8DD3,
	UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4,
	UNSIGNED_INT_SAMPLER_1D_ARRAY = 0x8DD6,
	UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7,
	UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE = 0x910A,
	UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910D,
	UNSIGNED_INT_SAMPLER_BUFFER = 0x8DD8,
	UNSIGNED_INT_SAMPLER_2D_RECT = 0x8DD5,

	IMAGE_1D = 0x904C,
	IMAGE_2D = 0x904D,
	IMAGE_3D = 0x904E,
	IMAGE_2D_RECT = 0x904F,
	IMAGE_CUBE = 0x9050,
	IMAGE_BUFFER = 0x9051,
	IMAGE_1D_ARRAY = 0x9052,
	IMAGE_2D_ARRAY = 0x9053,
	IMAGE_CUBE_MAP_ARRAY = 0x9054,
	IMAGE_2D_MULTISAMPLE = 0x9055,
	IMAGE_2D_MULTISAMPLE_ARRAY = 0x9056,

	INT_IMAGE_1D = 0x9057,
	INT_IMAGE_2D = 0x9058,
	INT_IMAGE_3D = 0x9059,
	INT_IMAGE_2D_RECT = 0x905A,
	INT_IMAGE_CUBE = 0x905B,
	INT_IMAGE_BUFFER = 0x905C,
	INT_IMAGE_1D_ARRAY = 0x905D,
	INT_IMAGE_2D_ARRAY = 0x905E,
	INT_IMAGE_CUBE_MAP_ARRAY = 0x905F,
	INT_IMAGE_2D_MULTISAMPLE = 0x9060,
	INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9061,
	
	UNSIGNED_INT_IMAGE_1D = 0x9062,
	UNSIGNED_INT_IMAGE_2D = 0x9063,
	UNSIGNED_INT_IMAGE_3D = 0x9064,
	UNSIGNED_INT_IMAGE_2D_RECT = 0x9065,
	UNSIGNED_INT_IMAGE_CUBE = 0x9066,
	UNSIGNED_INT_IMAGE_BUFFER = 0x9067,
	UNSIGNED_INT_IMAGE_1D_ARRAY = 0x9068,
	UNSIGNED_INT_IMAGE_2D_ARRAY = 0x9069,
	UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY = 0x906A,
	UNSIGNED_INT_IMAGE_2D_MULTISAMPLE = 0x906B,
	UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x906C,

	UNSIGNED_INT_ATOMIC_COUNTER = 0x92DB,
}

Uniform_Info :: struct {
	location, size: i32,
	kind: Uniform_Type,
	name: string,
}


get_uniforms_from_program :: proc(program: u32) -> (uniforms: map[string]Uniform_Info) {
	uniforms: map[string]Uniform_Info;

	uniform_count: i32;
	get_program_iv(program, ACTIVE_UNIFORMS, &uniform_count);

	counter : i32 = 0;
	for i in 0..uniform_count {
		using uniform_info: Uniform_Info;

		length: i32;
		cname: [256]u8;
		get_active_uniform(program, u32(i), 256, &length, &size, cast(^u32)&kind, &cname[0]);

		location = counter;
		name = strings.new_string(cast(string)cname[..length]); // @NOTE: These need to be freed
		uniforms[name] = uniform_info;

		counter += size;
	}

	return uniforms;
}

