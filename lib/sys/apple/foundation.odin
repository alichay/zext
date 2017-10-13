using import "core:c.odin"

Integer  :: c_long;
Uinteger :: c_ulong;

Point :: struct #ordered {
	x, y: f64
}
Size :: struct #ordered {
	w, h: f64
}
Rect :: struct #ordered {
	origin: Point,
	size: Size
}

Range :: struct #ordered {
	location, length: Uinteger
}

