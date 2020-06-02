fn void<write(string msg) {
	C.printf(msg)
}

fn void<writeln(string msg) {
	C.printf(msg)
}

fn voidptr<malloc(int size) {
	C.malloc(size)
}

fn int<sizeof(voidptr type) {
	C.sizeof(type)
}