module new

import os

pub fn new() {
	print('Project name: ')
	name := os.get_line()

	if os.is_dir(name) {
		exit(-1)
	}

	create_folder(name)
	create_x_mod(name)
	create_main(name)
}

fn create_folder(name string) {
	os.mkdir(name) or { panic(err) }
}

fn create_x_mod(name string) {
	content := 'Name: $name\nMain: ${name}.x'
	os.write_file('${name}/mod.x', content)
}

fn create_main(name string) {
	content := 'use <builtin.xd>\n\nfn void<main() {\n	writeln(\'Hello, world!\')\n}'
	os.write_file('${name}/${name}.x', content)
}