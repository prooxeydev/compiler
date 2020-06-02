module build

import os

struct XMod {
mut:
	path string
	name string
	main string
}

fn parse_x_mod(path string) XMod {
	mut mod := XMod{}
	mut content := os.read_file('$path/mod.x') or { panic(err) }
	content = content.trim_space()
	lines := content.split('\n')
	for line in lines {
		data := line.split(': ')
		match data[0] {
			'Name' {
				mod.name = data[1]
			}
			'Main' {
				mod.main = data[1]
			}
			else {

			}
		}
	}
	mod.path = path
	return mod
}