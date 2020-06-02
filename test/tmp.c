#include <stdlib.h>

typedef int X__int;
typedef char** X__string;
typedef void X__void;

void X__main ();
void X__writeln (X__string msg);

void X__writeln (X__string msg) {
	printf (msg);
}

void X__main () {
	X__writeln ("Hello world!");
}


int main() {
	X__main();
	return 0;
}
