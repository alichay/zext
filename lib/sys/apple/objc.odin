
foreign import "system:objc";

foreign objc {
	// NOTE: This function *must* be casted to be used.
	msg_send :: proc(self: id, op: SEL) #link_name "objc_msgSend" ---;
}

