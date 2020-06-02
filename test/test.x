use <builtin.xd>

fn void<a()
fn void<b()

fn void<a() {
	writeln('Hello, world!')
	b()
}

fn void<b() {
	a()
}

fn void<main() {
	a()
}
