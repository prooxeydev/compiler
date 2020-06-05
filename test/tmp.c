#include <stdio.h>
#include <stdlib.h>

typedef char X__int8;
typedef short X__int16;
typedef int X__int32;
typedef long X__int64;
typedef unsigned char X__uint8;
typedef unsigned short X__uint16;
typedef unsigned int X__uint32;
typedef unsigned long X__uint64;
typedef char* X__string;
typedef void X__void;
typedef void* X__voidptr;

#define NAME = "Name"

X__void X__main ();
X__void X__write (X__string msg);
X__void X__writeln (X__string msg);
X__voidptr X__malloc (X__int32 size);
X__string X__hello (X__string str);

X__void X__write (X__string msg) {
	printf (msg);
}

X__void X__writeln (X__string msg) {
	printf (msg);
}

X__voidptr X__malloc (X__int32 size) {
	return (X__voidptr) malloc(size);
}

X__string X__hello (X__string str) {
	return  str;
}

X__void X__main () {
	X__writeln (hello(hello('hi'));
	X__string a = "b";
	X__writeln (a);
}

int main() {
	X__main();
	return 0;
}
