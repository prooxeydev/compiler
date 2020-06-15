module main

import os
import new
import build

fn main() {
	args := os.args[1..]
	if args.len > 0 {
		match args[0] {
			'help' {
				println('Possible commands:')
				println('	build <Path>')
				println('	new')
			}
			'build' {
				build.build(args[1], args[2..])
			}
			'new' {
				new.new()
			}
			else {
				println('Type `help` to see possible commands')
			}
		}
	}
}