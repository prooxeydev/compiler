fn void<write(string msg) {
	C.printf(msg)
}

fn void<writeln(string msg) {
	C.printf(msg)
}

fn voidptr<malloc(int32 size) {
	return C.malloc(size) as voidptr
}
