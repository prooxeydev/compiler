#include <stdio.h>

typedef int X__int;
typedef char* X__string;
typedef void X__void;

void X__main ();
void X__writeln (X__string msg);
void X__a ();
void X__b ();

void X__writeln (X__string msg) {
	printf (msg);
}

void X__a () {
	X__writeln ("Hello world!");
	X__b ();
}

void X__b () {
	X__a ();
}

void X__main () {
	X__a ();
}

int main() {
	X__main();
	return 0;
}
