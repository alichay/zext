// NOTE: This file is not part of `os.odin`, and therefore
//       must be included explicitly.

foreign import cf "system:-fCoreFoundation";
using import "core:c.odin";
import "../../str.odin";

// NOTE: This is nowhere fully fleshed out.
//       As this is a massive library with a lot of
//       things that have analogues in the Odin stdlib or zext,
//       I'm just going to port things as I need them.
//
//       Pull requests are welcome.

Bundle :: struct #ordered {
	// TODO
}

Bundle_Ref     :: ^Bundle;
Plugin_Ref     :: ^Bundle;
Type_Ref       :: rawptr; // This rawptr is actually a rawptr, instead
                          // of a pointer to a struct that I'm too lazy
                          // to port properly.

String_Ref     :: rawptr; // This is a pointer to objective-c nonsense.
Allocator_Ref  :: rawptr; // ditto.
Index          :: c_long;
Options_Flags  :: c_ulong;

ALLOCATOR_DEFAULT := allocator_get_default();

String_Encoding :: enum {

	MacRoman = 0,
	WindowsLatin1 = 0x0500,  /* ANSI codepage 1252 */
	ISOLatin1 = 0x0201,      /* ISO 8859-1 */
	NextStepLatin = 0x0B01,  /* NextStep encoding*/
	ASCII = 0x0600,          /* 0..127 (in creating CFString, values greater than 0x7F are treated as corresponding Unicode value) */
	Unicode = 0x0100,        /* kTextEncodingUnicodeDefault  + kTextEncodingDefaultFormat (aka kUnicode16BitFormat) */
	UTF8 = 0x08000100,       /* kTextEncodingUnicodeDefault + kUnicodeUTF8Format */
	NonLossyASCII = 0x0BFF,  /* 7bit Unicode variants used by Cocoa & Java */

	UTF16 = 0x0100,          /* kTextEncodingUnicodeDefault + kUnicodeUTF16Format (alias of kCFStringEncodingUnicode) */
	UTF16BE = 0x10000100,    /* kTextEncodingUnicodeDefault + kUnicodeUTF16BEFormat */
	UTF16LE = 0x14000100,    /* kTextEncodingUnicodeDefault + kUnicodeUTF16LEFormat */

	UTF32 = 0x0c000100,      /* kTextEncodingUnicodeDefault + kUnicodeUTF32Format */
	UTF32BE = 0x18000100,    /* kTextEncodingUnicodeDefault + kUnicodeUTF32BEFormat */
	UTF32LE = 0x1c000100     /* kTextEncodingUnicodeDefault + kUnicodeUTF32LEFormat */
}

foreign cf {
	bundle_get_bundle_with_identifier    :: proc(bundle_id: String_Ref) -> Bundle_Ref                                                     #link_name "CFBundleGetBundleWithIdentifier"   ---;
	bundle_get_function_pointer_for_name :: proc(bundle: Bundle_Ref, function_name: String_Ref) -> rawptr                                 #link_name "CFBundleGetFunctionPointerForName" ---;
	string_create_with_cstring           :: proc(allocator: Allocator_Ref, string: ^u8, encoding: String_Encoding) -> String_Ref          #link_name "CFStringCreateWithCString"         ---;
	allocator_get_default                :: proc() -> Allocator_Ref                                                                       #link_name "CFAllocatorGetDefault"             ---;
	allocator_allocate                   :: proc(allocator: Allocator_Ref, size: Index, flags: Options_Flags) -> rawptr                   #link_name "CFAllocatorAllocate"               ---;
	allocator_realloccate                :: proc(allocator: Allocator_Ref, ptr: rawptr, new_size: Index, flags: Options_Flags) -> rawptr  #link_name "CFAllocatorReallocate"             ---;
	allocator_deallocate                 :: proc(allocator: Allocator_Ref, ptr: rawptr)                                                   #link_name "CFAllocatorDeallocate"             ---;
	release                              :: proc(iteem: Type_Ref)                                                                         #link_name "CFRelease"                         ---;

	// TODO(zachary): Can this be improved? There are two comments
	//                around the declaration of this function in the
	//                header that say "private" and "do not use".                    ¯\_(ツ)_/¯

	// make_constant_string :: proc(str: ^u8) -> CFStringRef                            #link_name "__CFStringMakeConstantString"    ---;
}

string_create_with_odin_string :: proc(allocator: Allocator_Ref, odin_str: string, encoding: String_Encoding = String_Encoding.ASCII) -> String_Ref #inline {
	
	c_str := str.new_c_string(odin_str); defer free(c_str);
	return string_create_with_cstring(allocator, c_str, encoding);
}

string_create_with_odin_string :: proc(odin_str: string, encoding: String_Encoding = String_Encoding.ASCII) -> String_Ref #inline {

	return string_create_with_odin_string(ALLOCATOR_DEFAULT, odin_str, encoding);
}

bundle_get_bundle_with_identifier :: proc(bundle_id: string) -> Bundle_Ref #inline {

	id := string_create_with_odin_string(bundle_id);
	defer release(Type_Ref(id));

	return bundle_get_bundle_with_identifier(id);
}

bundle_get_function_pointer_for_name :: proc(bundle: Bundle_Ref, function_name: string) -> rawptr #inline {

	name_cf_str := string_create_with_odin_string(function_name);
	defer release(Type_Ref(name_cf_str));

	return bundle_get_function_pointer_for_name(bundle, name_cf_str);
}