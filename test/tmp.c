#include <stdio.h>

typedef int X__int;
typedef char* X__string;
typedef void X__void;
typedef void* X__voidptr;

X__void X__main ();
X__void X__writeln (X__string msg);
X__voidptr X__malloc (X__int size);

X__void X__writeln (X__string msg) {
	printf (msg);
}

X__voidptr X__malloc (X__int size) {
	malloc (size);
}

X__void X__main () {
}

int main() {
	X__main();
	return 0;
}
